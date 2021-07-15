---
layout: post
title: Blogging from my android phone
---

A few days ago I published my first proper blog post, and I did it entirely from my android phone. I never once touched another device from the moment I wrote the first word until I brought the post online. This includes drafting the idea, writing and testing code snippets, finishing writing the whole post, previewing it and finally publishing it.

This might not seem special for someone using WordPress or another similar platform but my setup is a little different. This blog is hosted on github pages and uses jekyll to generate static html web pages from markdown. Each blog post is a .md file inside the repository and when new commits are pushed to master a github action runs all the proper Jekyll commands that convert the markdown files into the html pages that are served to the browser.

For me to publish my previous blog post I had to write markdown text and preview it, write postgresql code and test it and push the new file to the github repo. All of this from my phone, something I never though was possible. I will quickly share how I did it.

## text
Writing the normal text in the blog post does not require anything special, any note taking or text editor app will suffice. Personally because I am writing markdown I used [Markor](https://github.com/gsantner/markor), a text editor app for android with great markdown support. It allowed me to not only write but preview what the rendered version would approximately look like.

## code
For the code snippets I needed an instance of a postgresql database to test all the code and make sure it worked properly and there were no major problems with it. To solve this problem I used [termux](https://termux.com/), a terminal emulator and Linux environment that runs on Android. One of the cool things about it is the APT package management system with tons of different packages. I installed the postgresql package with `pkg install postgresql` and followed the [wiki page](https://wiki.termux.com/wiki/Postgresql) to set it up. After this I had a working postgresql database on my phone and could work on the code snippets.


## publish
After everything else was finished I had to publish the post by uploading the .md file with the new blog post to the repo. This was done in two steps, authenticating to github and pushing the changes, both of them using termux.

First I installed the openSSH package with `pkg install openssh`, this package is needed for ssh communications and to generate the ssh key pair used to authenticate. I generated the key pair into the ~/.ssh directory with `ssh-keygen -f ~/.ssh/github`. Then uploaded the contents of the github.pub key to my github account using the mobile browser. Finally changed the ssh config file in ~/.ssh/config to use the right key when accessing github by appending it the following:
```
Host github.com
 HostName github.com
 IdentityFile ~/.ssh/github
```

If everything was done correctly it should now be possible to ssh into github. To test this I entered `ssh -T git@github.com` in the terminal and got a message confirming I was authenticated.

The second step involved giving termux access to the shared storage in my phone, this is done by running `termux-setup-storage`. When the command finished running I had access to ~/storage/shared/, the directory where most of my files are. After that I installed the git package with `pkg install git` and inside the ~/storage/shared/ directory cloned the github repo using the usual git commands. Then put the markdown file containing my post in the proper folder, committed the changes and push them to github.

After the github action ran, the blog post was online and my laptop still inside my backpack.