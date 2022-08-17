# 实现python补全功能

参考：https://github.com/rkulla/pydiction

```shell
$ mkdir ~/.vim
$ mkdir ~/.vim/bundle
$ cd ~/.vim/bundle
$ git clone https://github.com/rkulla/pydiction.git

$ cp -r ~/.vim/bundle/pydiction/after/ ~/.vim

# 在 ~/.vimrc 文件中加入一下代码
filetype plugin on
let g:pydiction_location = '~/.vim/bundle/pydiction/complete-dict' 
let g:pydiction_menu_height = 3
```



其他参考：

- https://github.com/ycm-core/YouCompleteMe