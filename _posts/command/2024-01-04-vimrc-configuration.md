---
layout: post
title: .vimrc 설정
date: 2024-01-04 16:20
description: vim 설정 파일인 .vimrc에 대해서 정리 한다.
comments: true
categories: [Command]
tags: [CLI, Command, vim, Setting]
---

개인적으로 사용하고 있는 `.vimrc` 설정 파일의 내용을 정리한다.
```vimrc
set number              " 라인의 번호를 표시
set ai                  " auto indent
set si                  " smart indent
set cindent             " c style indent
set shiftwidth=4        " >>(인덴츠 들이기), <<(인덴츠 내어쓰기)시 공백을 4칸 사용
set tabstop=4           " tab을 4칸 공백으로 설정
set ignorecase          " 검색시 대소문자 무시
set hlsearch            " 검색시 검색 내용 하이라이트
set nocompatible        " 방향키로 이동 가능
set fileencodings=utf-8 " 파일 저장 인코딩 : utf-8
set bs=indent,eol,start " backspace 인덴츠, 라인의 끝, 라인의 시작에서 사용가능
set ruler               " 상태 표시줄에 커서 위치 표시
set title               " 제목 표시
set showmatch           " 매칭되는 괄호 표시
set showcmd             " 입력중인 명령어 표시
set wmnu                " (wildmenu) 명령모드에서 tab을 눌렀을 때 자동완성 가능한 목록 표시
set cursorline          " 입력중인 위치에 밑줄을 표시
syntax on               " 문법 하이라이트 on
filetype indent on      " 파일 종류에 따른 구문 강조
set mouse=a             " 커서 이동을 마우스로 가능
set expandtab           " 탭 입력시 스페이스를 사용
set listchars=eol:$,tab:>-,trail:~,extends:>,precedes:<,space:.
set list
hi  NonText     cterm=none  ctermfg=8   term=none
hi  SpecialKey  cterm=none  ctermfg=8

" Color value
" NR-16     | Color name
" 0         | Black
" 1         | Dark red
" 2         | Dark green
" 3         | Brown, Dark yellow
" 4         | Dark blue
" 5         | Dark magenta
" 6         | Dark cyan
"
" 7         | Light gray
" 8         | Dark gray
" 9         | Light red
" 10        | Light green
" 11        | Light yellow
" 12        | Light blue
" 13        | Light magenta
" 14        | Light cyan
" 15        | White

" 마지막으로 수정된 곳에 커서를 위치함
au BufReadPost *
\ if line("'\"") > 0 && line("'\"") <= line("$") |
\ exe "norm g`\"" |
\ endif
```

개인적으로는 개발용 IDE 설정의 공백문자표시(Show Whitespace) 기능을 사용하고 있어서, vim에서도 이를 사용하고 싶었다. 

`set list`는 공백문자를 보이도록 설정하는 부분이고, `set listchars`는 보이는 공백문자의 모양을 설정하는 부분이다. 

`set listchars`의 설정은 아래와 같다.
- eol : 줄 끝에 있는 공백(개행)문자
- tab : tab 문자
- trail : 줄 끝에 있는 공백문자
- extends : 줄이 길어서 다음 줄로 넘어간 부분
- precedes : 줄이 길어서 다음 줄로 넘어간 부분
- space : 공백문자

그 아래쪽 `hi`(`highlight`) 명령어는 색상을 설정하는 명령어이다. 

위와 같이 설정시 공백문자가 회색(Dark gray)으로 표시된다.