#   Contributors welcome!

Thank you very much for your interest in this project! There are plenty of ways you can support us. :-)


##  Code of Conduct

We like you to read and follow our [code of conduct](CODE_OF_CONDUCT.md) before contributing. Thank you.


##  Use it

The best and (probably) easiest way is to use one or more of the scripts. It would be very nice to share your thoughts with us. We love to hear from you.

If you have questions how to use it properly read the [documentation](README.md) carefully.


##  Report bugs

If you find something strange please report it to [our issue tracker](https://github.com/bheisig/i-doit-scripts/issues).


##  Make a wish

Of course, there are some features in the pipeline. However, if you have good ideas how to improve this application please let us know! Write a feature request [in our issue tracker](https://github.com/bheisig/i-doit-scripts/issues).


##  Requirements

Developer and build environments must meet at least these requirements:

*   [Git](https://git-scm.com/)
*   [ShellCheck](https://www.shellcheck.net/)
*   make

These dependencies are suggested:

*   lintian

For example, if you're running a Debian GNU/Linux run this command line as `root` user:

~~~ {.bash}
apt install build-essentials git make shellcheck lintian
~~~


##  Setup a development environment

If you like to contribute source code, documentation snippets, self-explaining examples or other useful bits, fork this repository, setup the environment and make a pull request.

~~~ {.bash}
git clone https://github.com/bheisig/i-doit-scripts.git
~~~

If you have a GitHub account create a fork first and then clone the repository.


##  Repository

After cloning the repository change to its project directory:

~~~ {.bash}
cd i-doit-scripts
~~~

There you find the following file structure:

~~~ {.bash}
.
├── CHANGELOG.md        # Changelog
├── CODE_OF_CONDUCT.md  # Code of conduct
├── CONTRIBUTING.md     # This file
├── cron                # Pre-defined cron jobs
├── docs                # Templates for GitHub
│   ├── issue_template.md
│   └── pull_request_template.md
├── .editorconfig       # Editor configuration settings
├── .gitattributes      # Git configuration settings
├── .gitignore          # Files/directories to be ignored by git
├── idoit               # Easy-use of the i-doit CLI
├── idoit-backup        # Backup i-doit files and databases
├── idoit-hotfix        # Deploy hot fixes
├── idoit-install       # Install i-doit on a GNU/Linux operating system
├── idoit-jobs          # Run important jobs automatically
├── idoit-pwd           # Alter passwords for various users and remove default users
├── idoit-restore       # Restore i-doit from backup
├── i-doit.sh           # Configuration settings
├── idoit-support       # Collect data about i-doit, installed add-ons and your system
├── LICENSE             # License information
├── Makefile            # Make rules (see above)
├── README.md           # Documentation
└── .travis.yml         # Configuration settings for Travis-CI continuous integration server
~~~

Now your system is ready for your contributions. Do not forget to commit your changes. When you are done consider to make a pull requests.

Notice, that any of your contributions merged into this repository will be [licensed under the AGPLv3](LICENSE).


##  Coding guidelines

There are no specific coding guidelines for shell scripts. But we encourage you to follow common guidelines specified by the shellcheck community. See their [wiki pages for details](https://github.com/koalaman/shellcheck/wiki/Checks).

Run `make shellcheck` to check your code. This makes sure your code follows the coding guidelines mentioned above. If any error/warning occurs please fix it before sending a pull request.

Don't forget to add new shell scripts to the [`Makefile`](Makefile). This is necessary for some make rules like `make shellsheck`.

If there are any questions just [raise an issue](https://github.com/bheisig/i-doit-scripts/issues).


##  Make rules

This project comes with some useful make rules:

| Command               | Description                                               |
| --------------------- | --------------------------------------------------------- |
| `make deb`            | Create a Debian GNU/Linux compatible distribution package |
| `make clean`          | Clean up project directory                                |
| `make install`        | Install shell scripts locally                             |
| `make lintian`        | Validate distribution package                             |
| `make shellcheck`     | Validate shell scripts                                    |
| `make uninstall`      | Uninstall shell scripts from local system                 |
