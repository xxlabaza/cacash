## Legal

By submitting a pull request, you represent that you have the right to license your contribution to the community, and agree by submitting the patch that your contributions are licensed under the Apache 2.0 [license](./LICENSE.txt).

## How to submit a bug report

Please ensure to specify the following:

* `CaCaSH` commit hash
* Contextual information (e.g. what you were trying to achieve with `CaCaSH`)
* Simplest possible steps to reproduce
  * More complex the steps are, lower the priority will be.
  * A pull request with failing test case is preferred, but it's just fine to paste the test case into the issue description.
* Anything that might be relevant in your opinion, such as:
  * Shell name, which you use
  * OS version and the output of `uname -a`

### Example

```
CaCaSH commit hash: 22ec043dc9d24bb011b47ece4f9ee97ee5be2757

Context:
While working with CaCaSH, I noticed
that not all arguments parse correctly.

Steps to reproduce:
1. ...
2. ...
3. ...
4. ...

Shell: BASH

$ uname -a
Linux beefy.machine 4.4.0-101-generic #124-Ubuntu SMP Fri Nov 10 18:29:59 UTC 2017 x86_64 x86_64 x86_64 GNU/Linux
```

## Writing a Patch

A good CaCaSH patch is:

1. Concise, and contains as few changes as needed to achieve the end result.
2. Tested, ensuring that any tests provided failed before the patch and pass after it.
3. Documented, adding API documentation as needed to cover new functions and properties.
4. Accompanied by a great commit message, using my commit message template.

### Commit Message Template

I require that your commit messages match my template. The easiest way to do that is to get git to help you by explicitly using the template. To do that, `cd` to the root of my repository and run:

    git config commit.template .dev/git.commit.template

The default policy for taking contributions is “Squash and Merge” - because of this the commit message format rule above applies to the PR rather than every commit contained within it.

### Formatting

Try to keep your lines less than 120 characters long so github can correctly display your changes.

### Extensibility

Try to make sure your code is robust to future extensions.

## How to contribute your work

Please open a pull request at https://github.com/xxlabaza/cacash, and then wait for code review.

After review you may be asked to make changes.  When you are ready, use the request re-review feature of github or mention the reviewers by name in a comment.
