git clone https://github.com/kaldi-asr/kaldi.git kaldi --origin upstream
cd kaldi
cd tools
extras/check_dependencies.sh || exit 1;
make
cd ../src
./configure --shared
make depend
make
