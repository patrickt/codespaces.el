# codespaces.el

[![check](https://github.com/patrickt/codespaces.el/actions/workflows/check.yml/badge.svg)](https://github.com/patrickt/codespaces.el/actions/workflows/check.yml)
![license](https://img.shields.io/github/license/patrickt/codespaces.el)

This package provides support for connecting to [GitHub Codespaces](https://github.com/features/codespaces) in Emacs via [TRAMP](https://www.gnu.org/software/tramp/). It provides a handy `completing-read` UI that lets you choose from all your created codespaces. Here's a screenshot (running with [vertico](https://github.com/minad/vertico)):

![](./screenshot.png)

Here is an example `use-package` declaration:

```emacs-lisp
(use-package codespaces
  :config (codespaces-setup)
  :bind ("C-c S" . #'codespaces-connect))
```

You will need to have the GitHub [command line
tools](https://cli.github.com) (`gh`) installed. If you use
`use-package-ensure-system-package`, Emacs can install them for you
automatically:

```emacs-lisp
(use-package use-package-ensure-system-package :ensure t)
(use-package codespaces
  :ensure-system-package gh
  :config (codespaces-setup))
```

# User-facing commands

- `codespaces-connect` brings up a list of codespaces, and upon
    selection opens a Dired buffer in `/workspaces` (the default
    Codespaces location).
- `codespaces-start`/`codespaces-stop` bring up a list of applicable
    codespaces and upon selection spawns a task that
    starts or stops the selected codespace.

# Missing features

- Should ensure that `gh codespace list` works okay.
- Should warn when trying to connect to a non-started codespace, and if
  so then start the codespace out-of-band before entering TRAMP, as
  otherwise we hit timeouts.
- Completion should sort codespaces by most-recently-used.
- There should be `dtache` support to activate codespaces without
  freezing the Emacs UI.

# Credits

Thanks to [Bas Alberts](https://github.com/anticomputer) for writing the
code to register `ghcs` as a valid TRAMP connection method.

# License

GPL3
