num_frames=5000000
subsample=2 # subsample all features with this periodicity, in the main E-M phase.
num_iters_init=20
num_iters=4
num_gselect=8 # Number of Gaussian-selection indices to use while training
               # the model.
min_gaussian_weight=0.0001
remove_low_count_gaussians=true

if [ -f path.sh ]; then . ./path.sh; fi

. parse_options.sh || exit 1;

# Filename with the training characteristics
data=$1
# Number of Gaussians
num_gauss=$2
# Directory to save
dir=$3

if [ -f $dir/final.dubm ]; then
	exit 0;
fi

mkdir -p $dir


# This tells the initialization program further ahead to read the features, note the pipe
all_feats="ark:copy-matrix scp:$data ark:- |"
#all_feats="ark:apply-cmvn-sliding --norm-vars=false --center=true --cmn-window=300 scp:$data ark:- |"

# Same as last one, but also subsamples the features
feats="ark:copy-matrix scp:$data ark:- | subsample-feats --n=$subsample ark:- ark:- |"
#feats="ark:apply-cmvn-sliding --norm-vars=false --center=true --cmn-window=300 scp:$data ark:- |"

gmm-global-init-from-feats --num-frames=$num_frames \
     --num-gauss=$num_gauss --num-iters=$num_iters_init \
    "$all_feats" $dir/0.dubm || exit 1;

gmm-gselect --n=$num_gselect $dir/0.dubm "$feats" \
      "ark:|gzip -c >$dir/gselect.JOB.gz"|| exit 1;


for x in `seq 0 $[$num_iters-1]`; do
	echo "$0: Training pass $x"
		# Accumulate stats.
		gmm-global-acc-stats "--gselect=ark:gunzip -c $dir/gselect.JOB.gz|" \
		$dir/$x.dubm "$feats" $dir/$x.JOB.acc || exit 1;
		if [ $x -lt $[$num_iters-1] ]; then # Don't remove low-count Gaussians till last iter,
			opt="--remove-low-count-gaussians=false" # or gselect info won't be valid any more.
		else
			opt="--remove-low-count-gaussians=$remove_low_count_gaussians"
		fi
		  gmm-global-est $opt --min-gaussian-weight=$min_gaussian_weight $dir/$x.dubm "gmm-global-sum-accs - $dir/$x.*.acc|" \
		  $dir/$[$x+1].dubm || exit 1;
		rm $dir/$x.*.acc $dir/$x.dubm

done

rm $dir/gselect.*.gz
mv $dir/$num_iters.dubm $dir/final.dubm || exit 1;
exit 0;
