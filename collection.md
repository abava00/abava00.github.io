---
layout: default
title: Collection test page
---
# このページはコレクション機能のテストページです

<ul>
  {% for count in site.test %}
    <li>
      <h2>{{ count.name }}</h2>
      <p><a href = "{{ count.url}}">ここ</a></p>
  <!--    <p>{{ count.content | markdownify }}</p> -->
    </li>
  {% endfor %}
</ul>
