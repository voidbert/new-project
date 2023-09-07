# new-project

A set of simple shell scripts and project templates, to make the creation of new projects easier.

To install it, use one of the following commands:

```bash
$ ./install.sh local       # Local installation (current user, in $HOME/.local)
$ sudo ./install.sh system # System installation (all users)
```

You will **need internet access**, to automatically download licenses from the
[GitHub API](https://docs.github.com/en/rest/licenses/licenses).

You can uninstall `new-project` with:

```bash
$ ./install.sh uninstall local       # For local installations
$ sudo ./install.sh uninstall system # For system installations
```

Projects can be created interactively, simply by running the `new-project` command.
