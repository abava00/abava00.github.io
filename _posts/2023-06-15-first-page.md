---
layout: post
title: "Github Pagesを作ったよ"
---



レポジトリだけ作って放置していたページをとりあえず表示できるぐらいにはしてみました．
Microsoftのストレージをこんな無駄なデータで損なわせることができるなんて興奮しますね．

ここから下は構築したときの覚え書き

- [構成](#構成)
- [ぺージ構築までの手順](#ぺージ構築までの手順)
- [Github Pagesレポジトリの作成とクローン](#github-pagesレポジトリの作成とクローン)
- [jekyll環境の構築](#jekyll環境の構築)
- [ポストの作成・編集](#ポストの作成編集)
- [ビルド](#ビルド)
- [その他設定](#その他設定)


# 構成

部位|使ったもの|理由
:--|:--|:--
環境 | WSL2:Ubuntu22.04 | 最初からあった．
ウェブページ | [Github Pages](https://docs.github.com/ja/pages/getting-started-with-github-pages/about-github-pages) | 無料で使える．
ページジェネレータ| [Jekyll](https://jekyllrb-ja.github.io/) | デフォルトでサポートされている．
テーマ| [Minima](https://github.com/jekyll/minima) | 一番スターが多かった．

# ぺージ構築までの手順
1. Github Pagesレポジトリの作成とクローン
2. jekyll環境の構築
3. ポストの作成
4. 編集
5. コミット

# Github Pagesレポジトリの作成とクローン
省略<br>
主に[ここ](https://docs.github.com/ja/pages/getting-started-with-github-pages/creating-a-github-pages-site)に従った．

# jekyll環境の構築
Github Pagesはデフォルトでjekyllをサポートしているのでそれを用いた．
jekyllを実行する為に構築する(必要ないかも)

rubyのインストール先を変更
これをやらないとgemの読み取り許可関係でエラーがでる
```
$ vim ~/.bashrc
  次を追記
    export GEM_HOME=~/.config/ruby
    export PATH=$PATH:~/.config/ruby/bin
```

rubyとその他をインストールする
```
# apt install ruby-full make g++
```

環境の構築
```
$ jekyll new *dirname*
$ vim *dirname*/Gemfile
  次を追記
    gem "minima"
$ bundle install
```

# ポストの作成・編集
ポストを作成する

ポストの形式はMarkdownとHTMLを指定できる．<br>
ファイル名は 日付＋タイトル の形にする必要があり，未来の日付は設定できない．

(例:
<script>
  var today = new Date();
  var year = today.getFullYear();
  document.write(((today.getFullYear() )) + "-" + ( "0" + today.getMonth()).slice(-2) + "-" + ("0" + today.getDay()).slice(-2)+ "-B-is-God.md");
</script>
)

```
$ vim *dirname*/_posts/*yyyy-mm-dd-title*.md
  次を追記
    ---
    layout: post
    title: "hello world"
    ---

    # This is Section title
      hello world for jekyll.

```

# ビルド
localhsotでページを確認する
```
$ cd *dirname*
$ bundle exec jekyll serve
```

ブラウザをつけて[`localhost:4000`](http://localhost:4000)を入力する．

# その他設定
`*dirname*/_config`に記述されている設定を変更することでサイト全体の設定を変更できる．

`_layouts`などのサイト構築用ファイルは自分で作成することでデフォルトの構築から変更させることが出来る．
