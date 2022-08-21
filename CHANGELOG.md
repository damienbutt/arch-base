# Changelog

## 1.0.0 (2022-08-21)


### Features

* add install script helper ([44d4005](https://github.com/damienbutt/arch-base/commit/44d4005527605ee537cf997263120657f08494ff))
* **locale:** add language setting to locale ([78e8bea](https://github.com/damienbutt/arch-base/commit/78e8bea22a5457963a9928a0772d1feae60937dc))
* **bashrc:** add skull emoji to root user prompt ([dd0774d](https://github.com/damienbutt/arch-base/commit/dd0774d8f48553ed772bdfafb355d9933ca995d8))
* check user input and ask again if incorrect ([f96a3c8](https://github.com/damienbutt/arch-base/commit/f96a3c82e40b4de9ace18a6cca2f0b8eb1101493))
* consolidate into a single script ([165c4de](https://github.com/damienbutt/arch-base/commit/165c4de4391345046ca34fe71b8ed60ed95036a1))
* **grub:** enable os prober ([248cbf1](https://github.com/damienbutt/arch-base/commit/248cbf126e696ec92e12f20585477d4c67c13be6))
* ensure luks container was created ([6e655d8](https://github.com/damienbutt/arch-base/commit/6e655d85ac8bba0b02781289ae8869da5b185654))
* ensure non-root user doesn't already exist ([5389941](https://github.com/damienbutt/arch-base/commit/5389941aaccaf8078ee1c23193a6f6710ccab916))


### Bug Fixes

* add -p flag to mkdir when creating dir for arch netboot ([7ae0efa](https://github.com/damienbutt/arch-base/commit/7ae0efa8afbf7605e7d098a4f1b9df5a5ef12d4f))
* change keymap to uk. mac-uk not working correctly ([199a465](https://github.com/damienbutt/arch-base/commit/199a46521f696f589a3b24a5b88b56255a05c24f))
* copy arch-chroot-user script to user directory ([061d585](https://github.com/damienbutt/arch-base/commit/061d5851f38c41e8cccdece12a7f782ed9bab00f))
* **bashrc:** copy bashrc to user dir ([dda4429](https://github.com/damienbutt/arch-base/commit/dda44291dd8a5deeee1568bec5162115d2fc94d6))
* copy final .env file to user dir ([fb96bc7](https://github.com/damienbutt/arch-base/commit/fb96bc7da0db349729c7812ff0c5ced7e0c9439d))
* copy new scripts to installation ([45c1185](https://github.com/damienbutt/arch-base/commit/45c1185e590dc5224ac6caaf56804b4923e86ec4))
* copy utils and env variables file to installation and source ([93f1056](https://github.com/damienbutt/arch-base/commit/93f1056339c48c91b0dfb110822b1dd6cf6096f3))
* dont re-copy root .bashrc ([f18332f](https://github.com/damienbutt/arch-base/commit/f18332f905efa6e43526a192da681178fdfbc09c))
* make chroot scripts executable once downloaded ([46d2c2d](https://github.com/damienbutt/arch-base/commit/46d2c2d0ed5b5e31e9da001441422cd11391d0ef))
* move all chroot script into dedicated files ([18ffbbe](https://github.com/damienbutt/arch-base/commit/18ffbbe214eae6efeb191ed57a2d496e8683f169))
* redirect curl downloads to local files ([c3ab652](https://github.com/damienbutt/arch-base/commit/c3ab6523a8134ba1c88b38132176d06f91d39402))
* remove SCRIPT_DIR variable ([308a7ef](https://github.com/damienbutt/arch-base/commit/308a7efa9b50104ce551073c9ad422b60f806255))
* run cleanup function after deleting files ([2f04235](https://github.com/damienbutt/arch-base/commit/2f04235bd02adccce516428899f528976b9fdf1e))
* set btrfs property on the directory, not the file ([706f461](https://github.com/damienbutt/arch-base/commit/706f4611044e004beaaf66c3c04090ad3214c57f))
* source chroot files from SCRIPT_DIR ([7941ad0](https://github.com/damienbutt/arch-base/commit/7941ad0140805f2e9dfa62930604f580faa8164b))
* source install-arch-base-utils.sh without piping ([a224f6f](https://github.com/damienbutt/arch-base/commit/a224f6f855d7a0d3b0c13bd71563176b991a8af9))
* touch empty swapfile ([a826a45](https://github.com/damienbutt/arch-base/commit/a826a45a139af9d1f61d2a1e17d1f1e8bee1084b))


### Documentation

* **contributing:** add CONTRIBUTING.md ([b985e8f](https://github.com/damienbutt/arch-base/commit/b985e8fe02f7311591b37affe797cc7d3cf9d715))
* **readme:** add dependabot as contributor ([fe07e50](https://github.com/damienbutt/arch-base/commit/fe07e50f43e5c31eb0c1be7dd88f7e565c1deaf8))
* update docs ([adf5d7d](https://github.com/damienbutt/arch-base/commit/adf5d7d6c2c6b9ed83a076e351a400e57f9c6e76))
* update install command ([f4c390e](https://github.com/damienbutt/arch-base/commit/f4c390ec10c770b8ef25b52604c1fe5c727a4938))
* **readme:** update README.md ([6d8dca3](https://github.com/damienbutt/arch-base/commit/6d8dca3bd9f97e0945c574dfdddb68f1784c813f))
* **readme:** update README.md ([48c6cc3](https://github.com/damienbutt/arch-base/commit/48c6cc3f40e3575dfbea744f6f23479e040038ba))
* **readme:** update README ([b105f4b](https://github.com/damienbutt/arch-base/commit/b105f4b2193e2a73f42ba2207d58bcadfa54a351))
* **readme:** update toc ([e994acd](https://github.com/damienbutt/arch-base/commit/e994acdb2e0c449507e9b4d6988d457087b32e73))
