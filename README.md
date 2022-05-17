# Arch-Base

<div align="center">
    <img align="center" src="./assets/img/archlinux-logo-dark-scalable.518881f04ca9.svg" alt="archlinux-logo" />
</div>

---

[![Conventional Commits](https://img.shields.io/badge/Conventional%20Commits-1.0.0-%23FE5196?logo=conventionalcommits&logoColor=white)](https://conventionalcommits.org)
[![Commitizen friendly](https://img.shields.io/badge/commitizen-friendly-brightgreen.svg)](http://commitizen.github.io/cz-cli/)
[![GitHub contributors](https://img.shields.io/github/contributors/damienbutt/arch-base)](#contributors)
[![MIT license](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

---

A collection of bash scripts to get Arch Linux up and running with ease.

<!-- This is a slightly opinionated setup that uses an EFI boot partition and a BTRFS root partition encrypted with LUKS. There is no swap partition. Swap is provided using the combination of a 2GB swapfile and 1GB of ZRAM. The ZRAM will be the priority swap space before anything is written to the swapfile on disk. -->

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

## Contents 📖

-   [Features :package:](#features-package)
-   [Usage :rocket:](#usage-rocket)
-   [Team :soccer:](#team-soccer)
-   [Contributors :sparkles:](#contributors-sparkles)
-   [Learn More :books:](#learn-more-books)
-   [LICENSE :balance_scale:](#license-balance_scale)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

<!-- ## Minimum Recommended Hardware

-   2 CPU Cores
-   2GB RAM. 1GB will be reserved for ZRAM swap.
-   10GB HDD. 2GB will be reserved for swap. -->

## Features :package:

-   EFI
-   BTRFS
-   LUKS Encryption
-   ZRAM
-   Swapfile

## Usage :rocket:

1. Download the latest version of the live ISO from [here](https://www.archlinux.org/download/) and boot into it.

    - If you're installing on bare metal, you'll need to burn the ISO to a USB flash drive. A great tool for this is [Etcher](https://etcher.io/). It is free and open source software.

2. (Optional) Setup WiFi.

    - If you need to connect to WiFi for network connectivity, follow the instructions [here](https://wiki.archlinux.org/title/Iwd#iwctl).

3. Confirm internet connectivity.

    ```bash
    ping -c 4 archlinux.org
    ```

4. (Optional) Set the root user password to allow SSH access. This is not required but recommended to allow copy/paste functionality.

    1. Get the IP address of the machine.

        ```bash
        ip a
        ```

    2. Set the root user password.

        ```bash
        passwd root
        ```

    3. From a remote machine SSH into the environment.

        ```bash
        ssh root@<ip>
        ```

5. Run the following command:

    ```bash
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/damienbutt/arch-base/master/install.sh)"
    ```

6. Follow prompts until the setup is complete.

## Team :soccer:

This project is maintained by the following person(s) and a bunch of [awesome contributors](https://github.com/damienbutt/arch-base/graphs/contributors).

<table>
    <tr>
        <td align="center">
            <a href="https://github.com/damienbutt">
                <img src="https://avatars.githubusercontent.com/damienbutt?v=4?s=100" width="100px;" alt=""/>
                <br />
                <sub><b>Damien Butt</b></sub>
            </a>
            <br />
        </td>
    </tr>
</table>

## Contributors :sparkles:

<!-- ALL-CONTRIBUTORS-BADGE:START - Do not remove or modify this section -->

[![All Contributors](https://img.shields.io/badge/all_contributors-1-orange.svg?style=flat-square)](#contributors-)

<!-- ALL-CONTRIBUTORS-BADGE:END -->

Thanks go to these awesome people ([emoji key](https://allcontributors.org/docs/en/emoji-key)):

<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->

<!-- markdownlint-restore -->
<!-- prettier-ignore-end -->

<!-- ALL-CONTRIBUTORS-LIST:END -->

This project follows the [all-contributors](https://allcontributors.org) specification.
Contributions of any kind are welcome!

Check out the [contributing guide](CONTRIBUTING.md) for more information.

## Learn More :books:

To learn more about Arch Linux, make sure to check out the [ArchWiki](https://wiki.archlinux.org/index.php/Main_Page).

## LICENSE :balance_scale:

[MIT](LICENSE)
