- `contributors.sh` - counts how many lines of code each contributor committed. This replaces my
                      need for GitHub Pro, needed to perform this action on private repos.

# GitHub Actions

The CI pipeline is very simple: it checks if the code is correctly formatted, and it builds the
project. These can be run locally, without any containerization.

However, you may want to run the CI actions in a environment similar to the one in a GitHub runner,
for example, to use the same version of `clang-format`. Our actions are compatible with
[`act`](https://nektosact.com). However, you are sure to expect a longer running time, as
`clang-format`, not available on `act`'s default Ubuntu image, needs to be installed.
