find . -type f -printf '%T@\t%p\n' |
sort -t $'\t' -g |
head -n -3 |
cut -d $'\t' -f 2- |
xargs rm
