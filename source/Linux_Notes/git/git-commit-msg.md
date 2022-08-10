# Git commit规范

## 格式

```bash
<type>(<scope>): <subject>
```

示例：

```bash
fix(ngRepeat): fix trackBy function being invoked with incorrect scope
```

## type

主要的提交类型如下：

<table border="1" cellpadding="10" cellspacing="10">
  <thead>
    <tr><th>Type</th><th>说明</th><th>备注</th></tr>
  </thead>
    <tbody>
      <tr><td>feat</td><td>提交新功能</td><td>常用</td></tr>
      <tr><td>fix</td><td>修复bug</td><td>常用</td></tr>
      <tr><td>docs</td><td>修改文档</td><td></td></tr>
      <tr><td>style</td><td>修改格式，例如格式化代码，空格，拼写错误等</td><td></td></tr>
      <tr><td>refactor</td><td>重构代码，没有添加新功能也没有修复bug</td><td></td></tr>
      <tr><td>test</td><td>添加或修改测试用例</td><td></td></tr>
      <tr><td>perf</td><td>代码性能调优</td><td></td></tr>
      <tr><td>chore</td><td>修改构建工具、构建流程、更新依赖库、文档生成逻辑</td><td>例如vendor包</td></tr>
  </tbody>
</table>

## scope

表示此次commit涉及的文件范围，可以使用`*`来表示涉及多个范围。

## subject

描述此次commit涉及的修改内容。

- 使用祈使句（动词开头）、动宾短语。
- 第一个字母不要大写。
- 不要以`.`句号结尾。

## Git commit工具

安装`commitizen`和`cz-conventional-changelog`。

```bash
$ npm install -g commitizen cz-conventional-changelog
$ echo '{ "path": "cz-conventional-changelog" }' > ~/.czrc
```

使用cz-cli

```bash
$ git cz
cz-cli@4.0.3, cz-conventional-changelog@3.0.1

? Select the type of change that you're committing: (Use arrow keys)
❯ feat:     A new feature
  fix:      A bug fix
  docs:     Documentation only changes
  style:    Changes that do not affect the meaning of the code (white-space, formatting, missing semi-colons, etc)
  refactor: A code change that neither fixes a bug nor adds a feature
  perf:     A code change that improves performance
  test:     Adding missing tests or correcting existing tests
(Move up and down to reveal more choices)
```
