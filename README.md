# powershell-tooling
Some PS methods to handle every-day-things @skybrud.dk



## DAILY TOOLING
`sky-showloglive -searchstring ""`
Use this to show the most current logfiles content, filtered by the searchstring-param


`sky-git-add -commitMsg "" -ppOnly` (push/pull only)
Used to add commits. Add all files, commits them with message (autoprefix casenumber), pull and push


`sky-git-grunt`  (pullFrontendGrunt)
Pull changes and grunt


`sky-git-npmgrunt`  (sky-pullFrontendNpmInstallGrunt)
Pull changes, npm install and grunt



## SETUP TOOLING
`sky-setup-local -repourl "" -customer "" -umbracoMainVersion 7 -casenumber ""`
Sets up repo from BitBucket, renames folder, runs npm install, grunt, sets up local IIS and starts VS Solution



`sky-setup-local-iis -inputCasenumber "" -inputFolderName "" -inputPath ""`
Sets up local IIS + AppPool
