---
layout: post
title: "クロスサイトスクリプティング(XSS)"
toc: true
---

# クロスサイトスクリプティング(XSS)の概要
英名 Cross-Site Scripting(XSS)

攻撃者がWebページ上で，任意のスクリプトを実行させることができる攻撃．

![攻撃概要](https://user-images.githubusercontent.com/60212516/251808017-0fafb7e6-82d8-4faa-aae0-ab1ec0d68f66.png)
*XSSの攻撃フロー<br>思いついたのをなんとなく描いただけなので実際に動くかはわからないです*


# 攻撃方法
HTTPリクエストのパラメータ(URLのクエリストリングとかinputタグに入力する文字列とか)にスクリプトを仕込む事によって攻撃を行う．

スクリプトを仕込む場所によって，反射型や蓄積型，DOM型のように名称が異なる．

## 反射型XSS
英名 Reflected Cross-Site Scripting

HTTPリクエストにスクリプトを仕込ませて，そのHTTPレスポンスの中でスクリプトを実行させる攻撃．<br>
URLの中にスクリプトを仕込むことで，URLを開くだけでスクリプトを実行させることができる．

![攻撃概要](https://user-images.githubusercontent.com/60212516/251808039-75562020-d1b0-4943-8b94-e47b16c585ca.png)
*反射型XSSの概要*


## 蓄積型XSS
英名 Stored Cross-Site Scripting

Webページのデータベースにスクリプトを仕込ませて，データが参照された時にスクリプトを実行させる攻撃．<br>
多くの人にデータを参照させると，多くの人にスクリプトを実行させることが出来る．

![攻撃概要](https://rocketnews24.com/wp-content/uploads/sites/2/2022/01/KaijiGame10.jpeg)
*蓄積型XSSの概要<br>これが攻撃文字列だった時が怖いですね*

## DOM型XSS
英名 DOM-based Cross-Site Scripting


javascriptなどでHTML要素を生成する関数にスクリプトを仕込ませて，スクリプトを実行させる攻撃．

:-:|:-:
document.write|好きなタグを生成できる．
innnerHTML|scriptタグは生成できない． imgタグとかを使う

<script>alert("test alert")</script>
