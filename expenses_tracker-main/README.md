# expenses_tracker

A new Flutter project.

## Getting Started

To download the code base, run the following command:

```shell
git clone https://github.com/OsamaMQ/expenses_tracker.git
```

## Adding Changes To The Repo

Before making changes, it's important to understand branches:

A branch is like a separate workspace that allows you to make changes without affecting the main code. This is crucial because:

- It keeps the main code stable and working
- Multiple developers can work on different features simultaneously
- Changes can be reviewed before being merged into the main code
- It prevents conflicts with other developers' work

The main branch should always contain stable, production-ready code.

To create a branch and upload changes, follow these steps:

1. Create and switch to a new branch:

```shell
git checkout -b your-branch-name
```

2. Make your changes to the code

3. Stage your changes:

```shell
git add .
```

4. Commit your changes:

```shell
git commit -m "describe your changes here"
```

5. Push your branch to GitHub:

```shell
git push origin your-branch-name
```

6. Create a Pull Request (PR) on GitHub:
   - Go to the repository on GitHub
   - Click "Pull Requests" tab
   - Click "New Pull Request"
   - Select your branch as the source
   - Select main branch as the target
   - Add a clear title and description explaining your changes
   - Request reviewers if needed
   - Click "Create Pull Request"

Your PR will allow team members to:

- Review your code changes
- Leave comments and suggestions
- Approve or request changes
- Merge your code into main when ready

## Getting Updates From The Repo

To get the latest updates from the repository, follow these steps:

1. Switch to the main branch:

```shell
git checkout main
```

2. Pull the latest changes:

```shell
git pull origin main
```
