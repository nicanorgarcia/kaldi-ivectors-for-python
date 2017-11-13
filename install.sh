git submodule init
git submodule update
echo "Enter the full path to the Kaldi installation root: "
read kaldi_root
shellname=$(basename $SHELL)
echo "export KALDI_ROOT=\"${kaldi_root}\"" >> "$HOME/.${shellname}rc"
echo "You will need to restart your shell for the changes to take effect."
