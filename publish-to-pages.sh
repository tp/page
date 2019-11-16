set -eux

git clone --quiet --branch="gh-pages" --depth=1 "https://x-access-token:${{ secrets.GITHUB_TOKEN }}@github.com/$GITHUB_REPOSITORY" .gh-pages

ls -lah .gh-pages

cp -r dist/* .gh-pages

ls -lah

cd .gh-pages

git push

# git subtree push --prefix dist "https://x-access-token:${{ secrets.GITHUB_TOKEN }}@github.com/$GITHUB_REPOSITORY" gh-pages