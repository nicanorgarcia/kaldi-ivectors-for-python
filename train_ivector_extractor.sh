
use_weights=false # set to true to turn on the regression of log-weights on the ivector.
num_iters=10
min_post=0.025 # Minimum posterior to use (posteriors below this are pruned out)
posterior_scale=1.0 # This scale helps to control for successve features being highly
                    # correlated.  E.g. try 0.1 or 0.3
num_samples_for_weights=3 # smaller than the default for speed (relates to a sampling method)
cleanup=true

num_gselect=4 # Number of Gaussian-selection indices to use while training the model.
num_feats=60
ivector_dim=400 # $(( $num_feats*$num_gselect )) # dimension of the extracted i-vector
if [ -f path.sh ]; then . ./path.sh; fi
. kaldi_ivector/parse_options.sh || exit 1;

fgmm_model=$1
data=$2
dir=$3


echo "The ivector dimension is: $ivector_dim"
srcdir=$(dirname $fgmm_model)

if [ -e $dir/final.ie ]; then
	exit 0;
fi


mkdir -p $dir


feats="ark:copy-matrix scp:$data ark:- |"

# Initialize the i-vector extractor using the FGMM input
#if [ $stage -le -2 ]; then
  cp $fgmm_model $dir/final.ubm || exit 1;
    fgmm-global-to-gmm $dir/final.ubm $dir/final.dubm || exit 1;
    ivector-extractor-init --ivector-dim=$ivector_dim --use-weights=$use_weights \
     $dir/final.ubm $dir/0.ie || exit 1
#fi

# Do Gaussian selection and posterior extracion

#if [ $stage -le -1 ]; then
#  echo $nj_full > $dir/num_jobs
  echo "$0: doing Gaussian selection and posterior computation"
  gmm-gselect --n=$num_gselect $dir/final.dubm "$feats" ark:- | \
  fgmm-global-gselect-to-post --min-post=$min_post $dir/final.ubm "$feats" ark:-  ark:- | \
  scale-post ark:- $posterior_scale "ark:|gzip -c >$dir/post.JOB.gz" || exit 1;
#else
#  if ! [ $nj_full -eq $(cat $dir/num_jobs) ]; then
#    echo "Num-jobs mismatch $nj_full versus $(cat $dir/num_jobs)"
#    exit 1
#  fi
#fi

x=0
while [ $x -lt $num_iters ]; do
#  if [ $stage -le $x ]; then
    rm $dir/.error 2>/dev/null

    Args=() # bash array of training commands for 1:nj, that put accs to stdout.
#    for j in $(seq $nj_full); do
      #Args[$j]=`echo "ivector-extractor-acc-stats --num-threads=$num_threads --num-samples-for-weights=$num_samples_for_weights $dir/$x.ie '$feats' 'ark,s,cs:gunzip -c $dir/post.JOB.gz|' -|" | sed s/JOB/$j/g`
#    done
	args="ivector-extractor-acc-stats --num-samples-for-weights=$num_samples_for_weights $dir/$x.ie '$feats' 'ark:gunzip -c $dir/post.JOB.gz|' -|"
    echo "Accumulating stats (pass $x)"
    ivector-extractor-sum-accs "$args" \
          $dir/acc.$x || exit 1;
#    for g in $(seq $nj); do
#      start=$[$num_processes*($g-1)+1]
#        ivector-extractor-sum-accs --parallel=true "${Args[@]:$start:$num_processes}" \
#          $dir/acc.$x.$g || touch $dir/.error &
#    done
#    wait
    #[ -f $dir/.error ] && echo "Error accumulating stats on iteration $x" && exit 1;
	#accs=""
	#for j in $(seq $nj); do
	#  accs+="$dir/acc.$x.$j "
	#done
	accs="$dir/acc.$x"
	echo "Summing accs (pass $x)"
	  ivector-extractor-sum-accs $accs $dir/acc.$x || exit 1;
    echo "Updating model (pass $x)"
    #nt=$[$num_threads*$num_processes] # use the same number of threads that
                                      # each accumulation process uses, since we
                                      # can be sure the queue will support this many.
	#ivector-extractor-est --num-threads=$nt $dir/$x.ie $dir/acc.$x $dir/$[$x+1].ie || exit 1;
	ivector-extractor-est $dir/$x.ie $dir/acc.$x $dir/$[$x+1].ie || exit 1;
	rm $dir/acc.$x
    if $cleanup; then
      rm $dir/$x.ie
    fi
#  fi
  x=$[$x+1]
done

mv $dir/$x.ie $dir/final.ie
rm $dir/post.JOB.gz
