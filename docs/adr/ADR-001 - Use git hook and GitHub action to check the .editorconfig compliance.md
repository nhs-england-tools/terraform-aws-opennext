# ADR-001: Use git hook and GitHub Action to check the `.editorconfig` compliance

>|              | |
>| ------------ | --- |
>| Date         | `15/05/2023` |
>| Status       | `RFC` |
>| Deciders     | `Engineering` |
>| Significance | `Construction techniques` |
>| Owners       | `Dan Stefaniuk, Amaan Ibn-Nasar` |

---

- [ADR-001: Use git hook and GitHub Action to check the `.editorconfig` compliance](#adr-001-use-git-hook-and-github-action-to-check-the-editorconfig-compliance)
  - [Context](#context)
  - [Decision](#decision)
    - [Assumptions](#assumptions)
    - [Drivers](#drivers)
    - [Options](#options)
      - [Options 1: The pre-commit project](#options-1-the-pre-commit-project)
      - [Options 2a: Custom shell script](#options-2a-custom-shell-script)
      - [Options 2b: Docker-based custom shell script](#options-2b-docker-based-custom-shell-script)
      - [Option 3: A GitHub Action from the Marketplace](#option-3-a-github-action-from-the-marketplace)
    - [Outcome](#outcome)
    - [Rationale](#rationale)
  - [Consequences](#consequences)
  - [Compliance](#compliance)
  - [Notes](#notes)
  - [Tags](#tags)

## Context

As part of the Repository Template project a need for a simple text formatting feature using the [EditorConfig](https://editorconfig.org/) rules was identified that is accessible and consistent for all contributors. To ensure that formatting rules are applied, a compliance check has to be implemented on a developer workstation and as a part of the CI/CD pipeline. This will establish a fast feedback loop and a fallback option, if the former has not worked.

## Decision

### Assumptions

This decision is based on the following assumptions that are used to form a set of generic requirements for the implementation as a guide. A solution should be

- Cross-platform and portable, supporting systems like
  - macOS
  - Windows WSL (Ubuntu)
  - Ubuntu and potentially other Linux distributions like Alpine
- Configurable
  - can run on a file or a directory
  - can be turned on/off entirely
- Run locally (aka developer workstation) and remotely (aka CI/CD pipeline)
- Reusable and avoid code duplication

### Drivers

Implementation of this compliance check (like text encoding, line endings, tabs vs. spaces etc.) will help with any potential debate or discussion, removing personal preferences and opinions, enabling teams to focus on delivering value to the product they work on.

Other linting tools like for example [Prettier](https://prettier.io/) and [ESLint](https://eslint.org/) are not considered here as they are code formatting tools dedicated to specific technologies and languages. The main drivers for this decision are the style consistency across all files in the codebase and to eliminate any disruptive changes introduced based on preferences. EditorConfig rules are recognised and supported by most if not all major editors and IDEs.

Here is the recommended ruleset:

```console
charset = utf-8
end_of_line = lf
indent_size = 2
indent_style = space
insert_final_newline = true
trim_trailing_whitespace = true
```

### Options

#### Options 1: The [pre-commit](https://pre-commit.com/) project

- Pros
  - Python is installed on most if not all platforms
  - A pythonist friendly tool
  - Well-documented
- Cons
  - Dependency on Python even for a non-Python project
  - Potential versioning issues with Python runtime and dependencies compatibility
  - Lack of process isolation, access to resources with user-level privileges
  - Dependency on multiple parties and plugins

#### Options 2a: Custom shell script

- Pros
  - Execution environment is installed everywhere, no setup required
  - Ease of maintainability and testability
  - It is a simple solution
- Cons
  - May potentially require more coding in Bash
  - Requires shell scripting skills

#### Options 2b: Docker-based custom shell script

This option is an extension built upon option 2a.

- Pros
  - Cross-platform compatibility
  - Isolation of the process dependencies and runtime
  - Docker is an expected dependency for most/all projects
- Cons
  - Requires Docker as a preinstalled dependency
  - Requires basic Docker skills

#### Option 3: A GitHub Action from the Marketplace

- Pros
  - Usage of a GitHub native functionality
- Cons
  - Reliance on the GitHub DSL (coding in yaml) may lead to less portable solution
  - Implementation of the functionality has to be duplicated for the git hook

### Outcome

The decision is to implement Option 2b.

### Rationale

A choice of shell scripting along with Docker offers a good support for simplicity, process isolation, portability across the operating systems and reuse of the same code and its configuration. This approach makes it consistent for a local environment and the CI/CD pipeline, where the process can be gated and compliance enforced.

## Consequences

As a result of the above decision

- a single Bash script will be implemented
- it will be placed in the `scripts/githooks` directory
- the name of the file will be `editorconfig-pre-commit.sh`
- there will be a `pre-commit` runner included
- the GitHub Action will call the git hook `editorconfig-pre-commit.sh` script directly
- and a couple of `Makefile` targets like `config`, `githooks-install` will be implemented to bootstrap the project

The intention of this decision is to guide any other git hook and GitHub Action implementations.

## Compliance

Both, the git hook and the GitHub Action should be executed automatically as part of the developer workflow.

## Notes

There is an emerging practice to use projects like [act](https://github.com/nektos/act) to make GitHub actions even more portable. The recommendation is for this tool to be assessed at further stages of the [nhs-england-tools/repository-template](https://github.com/nhs-england-tools/repository-template) project implementation, in the context of this decision record.

## Tags

`#maintainability, #testability, #simplicity, #security`
