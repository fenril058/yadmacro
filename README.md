# yadmacro.el --- yet another dmacro

This is the another implemetation of dynamic macro,
forked from [ndmacro.el](https://github.com/snj14/ndmacro.el).

## Usage

First turn on `global-yadmacro-mode`.
Then press `yadmacro-key` (default `<f9>`)
after making number incrementation, decrementation, or repeated key operations.

See the Function section for detail.

## Setting

The default `yadmacro-key` is `<f9>` you can change like below:

With [use-package](https://github.com/jwiegley/use-package):
```emacs-lisp
(use-package yadmacro
    :custom (yadmacro-key "C-t")
    :config (global-yadmadro-mode 1))
```

With [leaf](https://github.com/conao3/leaf.el)
```emacs-lisp
(leaf yadmacro
    :custom (yadmacro-key . "C-S-e")
    :global-minor-mode global-yadmadro-mode)
```

Of course, such a setting is also possible.
```emacs-lisp
(require 'yadmacro)
(global-set-key (kbd "<f9>") 'yadmacro)
```

## Functions

This package is the tool for automating repetitive tasks
by predicting and executing the next action based on repeated sequences of key operations
or sequential numbering.

It uses a special "repeat key" specified
by `yadmacro-key` to detect repetitions or sequential numbering of operations and execute them.

### Repetitions of operations

For example, if the user types
```
abcabc
```
and then presses the `yadmacro-key`,
yadmacro.el will detect the repetition of the input operation "abc" and execute it,
resulting in the text becoming:
```
abcabcabc
```

Similarly, if the user types
```
abcdefab
```
and then presses the `yadmacro-key`,
yadmacro.el will interpret this as a repetition of the input "abcdef",
predict and execute the remaining part "cdef",
resulting in the text becoming:
```
abcdefabcdef
```

Pressing the `yadmacro-key` again will repeat the input "abcdef",
resulting in the text becoming:
```
abcdefabcdefabcdef
```

### Sequential numbering operations

For example, if the user types:
```
100,101,
```
and then presses the `yadmacro-key`,
yadmacro.el recognizes a string consisting of numbers from 0 to 9 as a number,
and repeats the input operation while increasing or decreasing that number.
The resulting string will be:
```
100,101,102,
```
The prediction for whether to increase or decrease the number,
and by how much, is arbitrary.

However, when decreasing the number,
if the result becomes negative, zero is returned.
Once it reaches zero, it will not decrease further.

When the leading digits of the numerical part are filled with one or more `0`'s,
the upper digits are also filled with `0`'s to match the number of columns.
For example:
```
abc001.txt
abc002.txt
```
If you type this and then press the `yadmacro-key`, the result will be:
```
abc001.txt
abc002.txt
abc003.txt
```

You can increase or decrease multiple numbers simultaneously. For example:
```
001010
002009
```

If you type this and then press the `yadmacro-key`, the result will be:
```
001010
002009
003008
```


#### Broken example

The example below was suggested:
```
2x1=2
2x2=4
```

If you type this and then press the `yadmacro-key`, the result will be EXPECTED:
```
2x1=2
2x2=4
2x3=6
```

BUT, the result will be:
```
2x1=2
2x2=4
3x2=6
```

I think the behvior is undesirable.

## History

### dmacro

The original version of `dmacro.el` was written and published
by 増井俊之 <masui@ptiecan.com> and 太和田誠 on 1993-04-14.
On 1995-3-30 増井 modified it for Emacs 19.
This version is published 増井's github page:
<https://github.com/masui/DynamicMacro/blob/master/emacs/dmacro.el>.

On 2002-03, it was extended for XEmacs by 小畑英司 & 峰伸行,
This version can be seen here:
<http://www.pitecan.com/papers/JSSSTDmacro/dmacro.el>.

Now,`dmacro.el` is being maintained and developed by
[emacs-jp](https://emacs-jp.github.io/) community.
The repository is here:
<https://github.com/emacs-jp/dmacro>.


### ndmacro

Another version of dynamic macro `ndmacro.l` was developed by kia on 2003-06-30 for
[xyzzy](https://github.com/xyzzy-022/xyzzy).
This package supports not only repeated key sequence but also sequential numbering.
The original website is now disappeared but archived here:
<https://web.archive.org/web/20190330074136/http://www.geocities.jp/kiaswebsite/xyzzy/ndmacro.l.txt>.

The Emacs version of `ndmacro.el` was written by snj14 on 2012-02-08 and
is published here: <https://github.com/snj14/ndmacro.el>.
The repository `yadmaro.el` was forked from `ndmacro.el`.


## Reference (Japanese)

- [masui/Dynamic Macro (Scrapbox)](https://scrapbox.io/masui/Dynamic_Macro)
- [増井ラボノート コロンブス日和 第6回 Dynamic Macro (gihyo.jp)](https://gihyo.jp/dev/serial/01/masui-columbus/0006)
