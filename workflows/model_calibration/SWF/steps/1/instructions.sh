module purge all
module load R/4.3.0
module load git
CUR_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [[ "$CUR_BRANCH" != "main" ]]; then
echo 'The git branch is not `main`.)
Exiting' 1>&2
exit 1
fi
git pull
Rscript -e "renv::init(bare = TRUE)"
Rscript -e "renv::restore()"
