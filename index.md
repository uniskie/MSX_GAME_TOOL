## ブラウザで動作するツール

### MSX/MSX2版ハイドライド3用

- [MSX1/2版 ハイドライドⅢ PACセーブデータエディタ](./MEGA_UTIL/hydlide3_pac_editor.html)

### FC版/MSX2版ファイナルファンタジー用

- [FC版/MSX2版 ファイナルファンタジー セーブデータエディタ](./FF1SaveEditor/ff1_editor.html)

- [MSX2版 ファイナルファンタジー スプライト表示ツール](./FF1SaveEditor/FFSprPreview.html)


## 記事一覧

## ドキュメント一覧

{% assign dirs_str = "" %}
{% for p in site.pages %}
{% if p.path contains ".md" and p.url != page.url and p.dir %}
{% assign dirs_str = dirs_str | append: p.dir | append: "|" %}
{% endif %}
{% endfor %}
{% if dirs_str != "" %}
{% assign dirs = dirs_str | split: "|" | uniq | sort %}
{% for d in dirs %}
{% if d != "" %}
{% if d == "/" %}
### トップ階層
{% else %}
### {{ d | remove_first: "/" }}
{% endif %}
{% for p in site.pages %}
{% if p.path contains ".md" and p.url != page.url and p.dir == d %}
- [{{ p.title | default: p.name }}]({{ p.url | relative_url }})
{% endif %}
{% endfor %}
{% endif %}
{% endfor %}
{% endif %}
