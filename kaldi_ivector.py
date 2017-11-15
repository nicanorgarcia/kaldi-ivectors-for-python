import os
from kaldi_io import kaldi_io
import numpy as np

def gen_feats_file(data_feats,ids,feat_filename):
    """
    This function goes through the contents of a Kaldi script file (.scp) and
    selects the lines that match each element in ids and then stores this
    subset in feat_filename.

    Inputs:
        data_feats: The contents of the .scp file in a Numpy array (two columns)
        ids: Numpy array with the patterns to match
        feat_filename: Path to store the file with the subset
    """
    if not os.path.isfile(feat_filename) :
        new_feats=np.empty((0,2))
        for iid in ids:
            indices = [i for i, v in enumerate(data_feats[:,0]) if iid in v]
            new_feats=np.vstack((new_feats,data_feats[indices,:]))
        np.savetxt(feat_filename,new_feats,fmt="%s")


def train(feat_file,model_dir,M,ivector_dim=None,num_gselect=None):
    """
    This function will call the Bash script to train an i-vector extractor (and its corresponding UBM)
    Inputs:
        M: Number of Gaussians in the UBM
        ivector_dim: dimension of the i-vectors
        feat_file: Path to the Kaldi script (.spc) file with the features to use for i-vector training
        model_dir: Path where the model will be stored. It will create a sub-folder according to the number of Gaussians.
    Returns:
        Nothing
    """
    if num_gselect==None or ivector_dim == None:
        k=np.log2(M)
    if num_gselect==None:
        num_gselect=k+1
    if ivector_dim==None:
        # Read to obtain the dimension of the feature vector
        for key,mat in kaldi_io.read_mat_scp(feat_file):
            feat_dim=mat.shape[1]
            break
        ivector_dim=k*feat_dim
    os.system("./train_ivector_models.sh "+str(M) +" "+ str(ivector_dim) + " " + str(num_gselect) + " " + feat_file + " " + model_dir)

def extract(src_dir,feat_file,ivectors_dir,num_gselect):
    """
    The Bash script checks if the i-vectors have been extracted already.
    Inputs:
        src_dir: Model with the i-vector extractor (generated with train_ivector_models)
        feat_file: Path to the Kaldi script (.spc) file with the features to use for i-vector training
        ivectors_dir: Path where the i-vectors will be stored
    Returns:
        ivectors: numpy array with the extracted i-vectors
        keys: numpy array with the keys (ids) of each i-vector

    """
    os.system("./extract_ivectors.sh --num-gselect "+str(num_gselect)+ " " + src_dir + " " + feat_file + " " + ivectors_dir)Z
    keys=[]
    ivectors=np.empty((0,0))
    for key,mat in kaldi_io.read_vec_flt_scp(ivectors_dir+'/ivector.scp'):
        if ivectors.shape[1] != mat.shape[0]:
            ivectors=ivectors.reshape((0,mat.shape[0]))
        ivectors=np.vstack((ivectors,mat))
        keys.append(key)

    ivectors=np.asarray(ivectors)
    keys=np.asarray(keys)
    return ivectors,keys
