---
title: "Sed and Awk"
toc: true
#toc_label: "Sed and Awk"
#toc_icon: "cog"
categories: [ sed, awk ]
tags:
  - linux
  - sed
  - awk
---

这是对 sed 和 awk 文本处理实用程序的简要介绍。我们将在这里只处理一些基本命令，但这足以理解 shell 脚本中的简单 sed 和 awk 结构。

**sed**：非交互式文本文件编辑器

**awk**：具有 C 风格语法的面向字段的模式处理语言

## Sed

Sed 是一个非交互式流编辑器。它接收来自标准输入或文件的文本输入，对输入的指定行执行某些操作，一次一行，然后将结果输出到标准输出或文件。在 shell 脚本中，sed 通常是管道中的几个工具组件之一。

Sed 根据传递给它的地址范围（**如果未指定地址范围，则默认为所有行**）确定它将在其输入的哪些行上进行操作。通过行号或要匹配的模式指定此地址范围。例如，`3d` 向 sed 发出信号以删除输入的第 3 行，而 `/Windows/d` 告诉 sed 您希望删除包含与“Windows”匹配的输入的每一行。

在 sed 工具包中的所有操作中，我们将主要关注三个最常用的操作。这些是 **p**rinting (to `stdout`), **d**eletion, and **s**ubstitution。

**sed 基本运算符**

| Operator                               | Name       | Effect                                                       |
| -------------------------------------- | ---------- | ------------------------------------------------------------ |
| `[address-range]/p`                    | print      | 打印 [指定地址范围]                                          |
| `[address-range]/d`                    | delete     | 删除[指定地址范围]                                           |
| `s/pattern1/pattern2/`                 | substitute | 将每行中 pattern1 的第一个实例替换为 pattern2                |
| `[address-range]/s/pattern1/pattern2/` | substitute | 在地址范围内，将一行中 pattern1 的第一个实例替换为 pattern2  |
| `[address-range]/y/pattern1/pattern2/` | transform  | 在地址范围内，将 pattern1 中的任何字符替换为 pattern2 中的相应字符 (相当于 **tr**) |
| `[address] i pattern Filename`         | insert     | 在文件 Filename 中指定的地址插入模式。通常与 -i 选项一起使用。 |
| `g`                                    | global     | 对每个匹配的输入行中的每个模式匹配进行操作                   |

> 除非将 g（全局）运算符附加到替换命令，否则替换仅对每行中模式匹配的第一个实例进行

在命令行和 shell 脚本中，sed 操作可能需要引用和某些选项。

```shell
$ sed -e '/^$/d' $filename
# -e 选项导致下一个字符串被解释为编辑指令。
# （如果只向 sed 传递一条指令，“-e”是可选的。）
#  强引号 ('') 保护指令中的 RE 字符
#+ 来自脚本主体将其重新解释为特殊字符。
#（这为 sed 保留了指令的 RE 扩展。）
#
# 对文件 $filename 中包含的文本进行操作。
```

在某些情况下，sed 编辑命令不适用于单引号。

```shell
$ filename=file1.txt
$ pattern=BEGIN

$ sed "/^$pattern/d" "$filename"  # 按规定工作。
#$ sed '/^$pattern/d' "$filename"   有意想不到的结果。
#        在这种情况下，使用强引用 (' ... ')，
#+      "$pattern" 不会扩展为 "BEGIN"。
```

> Sed 使用 -e 选项指定以下字符串是一条指令或一组指令。如果字符串中只包含一条指令，则可以省略。

```shell
sed -n '/xzy/p' $filename
# -n 选项告诉 sed 只打印那些与模式匹配的行。
# 否则将打印所有输入行。（取消打印输入行，不自动打印模式空间）
# 这里不需要 -e 选项，因为只有一个编辑指令。
```

**sed 运算符示例**

| Notation                                                     | Effect                                                       |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| `8d`                                                         | 删除第 8 行输入。                                            |
| `/^$/d`                                                      | 删除所有空行。                                               |
| `1,/^$/d`                                                    | 从输入的开头删除直到并包括第一个空行。                       |
| `/Jones/p`                                                   | 仅打印包含“Jones”的行（使用 -n 选项）。                      |
| `s/Windows/Linux/`                                           | 将每个输入行中找到的“Windows”的第一个实例替换为“Linux”。     |
| `s/BSOD/stability/g`                                         | 将每个输入行中找到的每个“BSOD”实例都替换为“stability”。      |
| `s/ *$//`                                                    | 删除每行末尾的所有空格。                                     |
| `s/00*/0/g`                                                  | 将所有连续的零序列压缩成一个零。                             |
| `echo "Working on it." | sed -e '1i How far are you along?'` | 打印“How far are you along?”作为第一行，“Working on it”作为第二行。（`-i` 在指定行之前插入内容） |
| `5i 'Linux is great.' file.txt`                              | 在文件 file.txt 的第 5 行之前插入“Linux is great.”。         |
| `/GUI/d`                                                     | 删除所有包含“GUI”的行。                                      |
| `s/GUI//g`                                                   | 删除“GUI”的所有实例，保留每行的其余部分。                    |

用一个长度为零的字符串替换另一个字符串相当于在输入行中删除该字符串。这使该行的其余部分保持不变。将 s/GUI// 应用于该行

```
The most important parts of any application are its GUI and sound effects
```

