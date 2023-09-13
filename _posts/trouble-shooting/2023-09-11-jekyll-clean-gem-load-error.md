---
layout: post
title: jekyll clean 명령시 'Gem::LoadError' 오류 해결
date: 2023-09-11 15:20
description: jekyll clean 시 발생하는 오류에 대한 조치
comments: true
categories: [Trouble Shooting]
tags: [Trouble Shooting, Jekyll, Blog, Ruby]
---

## 상황 설명.
로컬에서 블로그 내용 검토를 위해 `jekyll clean`, `jekyll build` 명령을 실행시 아래와 같은 오류가 발생하였다.
```shell
$ jekyll clean
/Users/xxx/.local/share/gem/ruby/3.2.0/gems/bundler-2.4.14/lib/bundler/runtime.rb:304:in `check_for_activated_spec!': You have already activated public_suffix 5.0.3, but your Gemfile requires public_suffix 5.0.1. Prepending `bundle exec` to your command may solve this. (Gem::LoadError)
	from /Users/xxx/.local/share/gem/ruby/3.2.0/gems/bundler-2.4.14/lib/bundler/runtime.rb:25:in `block in setup'
	from /Users/xxx/.local/share/gem/ruby/3.2.0/gems/bundler-2.4.14/lib/bundler/spec_set.rb:165:in `each'
	from /Users/xxx/.local/share/gem/ruby/3.2.0/gems/bundler-2.4.14/lib/bundler/spec_set.rb:165:in `each'
	from /Users/xxx/.local/share/gem/ruby/3.2.0/gems/bundler-2.4.14/lib/bundler/runtime.rb:24:in `map'
	from /Users/xxx/.local/share/gem/ruby/3.2.0/gems/bundler-2.4.14/lib/bundler/runtime.rb:24:in `setup'
	from /Users/xxx/.local/share/gem/ruby/3.2.0/gems/bundler-2.4.14/lib/bundler.rb:162:in `setup'
	from /Users/xxx/.local/share/gem/ruby/3.2.0/gems/jekyll-4.3.2/lib/jekyll/plugin_manager.rb:52:in `require_from_bundler'
	from /Users/xxx/.local/share/gem/ruby/3.2.0/gems/jekyll-4.3.2/exe/jekyll:11:in `<top (required)>'
	from /Users/xxx/.rbenv/versions/3.2.2/bin/jekyll:25:in `load'
	from /Users/xxx/.rbenv/versions/3.2.2/bin/jekyll:25:in `<main>'
```

## 구글 검색
오류 내용으로 구글 검색하였고, 아래 URL 내용을 참고하여 조치 하였다.

https://stackoverflow.com/questions/6317980/you-have-already-activated-x-but-your-gemfile-requires-y

## 조치 내용.
```shell
$ bundle clean --force
Removing addressable (2.8.5)
Removing google-protobuf-3.24.3-arm64 (darwin)
Removing jekyll-feed (0.17.0)
Removing jekyll-sass-converter (3.0.0)
Removing minima (2.5.1)
Removing public_suffix (5.0.3)
Removing rexml (3.2.6)
Removing rouge (4.1.3)
Removing sass-embedded-1.66.1-arm64 (darwin)
```
 이후 정상 작동 하였다.
 
```shell
$ jekyll clean
Configuration file: /Volumes/litlssd/docs/litlcity/_config.yml
           Cleaner: Nothing to do for /Volumes/litlssd/docs/litlcity/_site.
           Cleaner: Nothing to do for /Volumes/litlssd/docs/litlcity/.jekyll-metadata.
           Cleaner: Removing /Volumes/litlssd/docs/litlcity/.jekyll-cache...
           Cleaner: Nothing to do for .sass-cache.
```
