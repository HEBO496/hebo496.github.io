yarn build
cd blog/.vuepress/dist
git init
git add -A
git commit -m 'deploy'
git push -f https://github.com/HEBO496/hebo496.github.io.git master
cd /d %~dp0
