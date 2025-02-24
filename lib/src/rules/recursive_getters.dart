// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

import '../analyzer.dart';

const _desc = r'Property getter recursively returns itself.';

const _details = r'''
**DON'T** create recursive getters.

Recursive getters are getters which return themselves as a value.  This is
usually a typo.

**BAD:**
```dart
int get field => field; // LINT
```

**BAD:**
```dart
int get otherField {
  return otherField; // LINT
}
```

**GOOD:**
```dart
int get field => _field;
```

''';

class RecursiveGetters extends LintRule {
  RecursiveGetters()
      : super(
            name: 'recursive_getters',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addFunctionDeclaration(this, visitor);
    registry.addMethodDeclaration(this, visitor);
  }
}

class _BodyVisitor extends RecursiveAstVisitor {
  final LintRule rule;
  final ExecutableElement element;
  _BodyVisitor(this.element, this.rule);

  @override
  visitListLiteral(ListLiteral node) {
    if (node.isConst) return null;
    return super.visitListLiteral(node);
  }

  @override
  visitSetOrMapLiteral(SetOrMapLiteral node) {
    if (node.isConst) return null;
    return super.visitSetOrMapLiteral(node);
  }

  @override
  visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.staticElement == element) {
      if (node.parent is! PrefixedIdentifier) {
        rule.reportLint(node);
      }
    }

    return super.visitSimpleIdentifier(node);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    // getters have null arguments, methods have parameters, could be empty.
    if (node.functionExpression.parameters != null) return;

    _verifyElement(node.functionExpression, node.declaredElement);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    // getters have null arguments, methods have parameters, could be empty.
    if (node.parameters != null) return;

    _verifyElement(node.body, node.declaredElement);
  }

  void _verifyElement(AstNode node, ExecutableElement? element) {
    if (element == null) return;
    node.accept(_BodyVisitor(element, rule));
  }
}
