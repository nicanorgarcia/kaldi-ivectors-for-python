source path.sh

num_iters=4
subsample=2
min_gaussian_weight=0.0001
remove_low_count_gaussians=true
num_gselect=4 # Number of Gaussian-selection indices to use while training the model.

if [ -f path.sh ]; then . ./path.sh; fi
. kaldi_ivector/parse_options.sh || exit 1;

data=$1
srcdir=$2
dir=$3


if [ -f $dir/final.ubm ]; then
	exit 0;
fi

mkdir -p $dir

## Set up features.
feats="ark:copy-matrix scp:$data ark:- | subsample-feats --n=$subsample ark:- ark:- |"


#if [ $stage -le -2 ]; then
  if [ -f $srcdir/final.dubm ]; then # diagonal-covariance in $srcdir
      gmm-global-to-fgmm $srcdir/final.dubm $dir/0.ubm || exit 1;
  elif [ -f $srcdir/final.ubm ]; then
    cp $srcdir/final.ubm $dir/0.ubm || exit 1;
  else
    echo "$0: in $srcdir, expecting final.ubm or final.dubm to exist"
    exit 1;
  fi
#fi

#if [ $stage -le -1 ]; then
  echo "$0: doing Gaussian selection (using diagonal form of model; selecting $num_gselect indices)"
  gmm-gselect --n=$num_gselect "fgmm-global-to-gmm $dir/0.ubm - |" "$feats" \
    "ark:|gzip -c >$dir/gselect.JOB.gz" || exit 1;
#fi

x=0
while [ $x -lt $num_iters ]; do
  echo "Pass $x"
#  if [ $stage -le $x ]; then
      fgmm-global-acc-stats "--gselect=ark:gunzip -c $dir/gselect.JOB.gz|" $dir/$x.ubm "$feats" \
      $dir/$x.JOB.acc || exit 1;

    if [ $[$x+1] -eq $num_iters ];then
      lowcount_opt="--remove-low-count-gaussians=$remove_low_count_gaussians" # as specified by user.
    else
    # On non-final iters, we in any case can't remove low-count Gaussians because it would
    # cause the gselect info to become out of date.
      lowcount_opt="--remove-low-count-gaussians=false"
    fi
    fgmm-global-est $lowcount_opt --min-gaussian-weight=$min_gaussian_weight --verbose=2 $dir/$x.ubm "fgmm-global-sum-accs - $dir/$x.*.acc |" \
      $dir/$[$x+1].ubm || exit 1;
    $cleanup && rm $dir/$x.*.acc $dir/$x.ubm
#  fi
  x=$[$x+1]
done

$cleanup && rm $dir/gselect.*.gz

rm $dir/final.ubm 2>/dev/null
mv $dir/$x.ubm $dir/final.ubm || exit 1;
