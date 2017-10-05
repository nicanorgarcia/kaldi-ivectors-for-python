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
import kaldi_ivector as ivector

M=2
ivector_dim=2
ivector.train(M,ivector_dim,'example_data/example_train.scp','example_data/example_model')
ivectors,keys=ivector.extract('example_data/example_model/extractor', 'example_data/example_test.scp','example_data/ivectors/')

```
