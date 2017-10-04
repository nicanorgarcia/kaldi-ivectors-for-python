# kaldi-ivectors-for-python
This repository allows to use kaldi to train an i-vector extractor and extract i-vectors through a python interface. Far from perfect as it uses os.system calls.


### Installation

To install please run

```sh
install.sh
```


### Example:
To run both the training and then extract the i-vector you would
```python
import kaldi_ivector

M=... # Number of Gaussians
ivector_dim=... # Dimension of the i-vector
feat_file=... # Full path to the Kaldi script file with the features to train the i-vector extractor
model_dir=... # Full path where the model will be stored
kaldi_ivector.train_ivector_models(M,ivector_dim,feat_file,model_dir)
src_dir=model_dir+'/M'+str(M)+'/extractor_gi'
feat_file=... # Full path to the Kaldi script file with the features to extract i-vectors
ivectors_dir=... # Full path to the directory where the i-vectors will be stored
ivectors,keys=kaldi_ivector.extract_ivectors(src_dir,feat_file,ivectors_dir):
```
