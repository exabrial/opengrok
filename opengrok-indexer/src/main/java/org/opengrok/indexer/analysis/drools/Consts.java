/*
 * CDDL HEADER START
 *
 * The contents of this file are subject to the terms of the
 * Common Development and Distribution License (the "License").
 * You may not use this file except in compliance with the License.
 *
 * See LICENSE.txt included in this distribution for the specific
 * language governing permissions and limitations under the License.
 *
 * When distributing Covered Code, include this CDDL HEADER in each
 * file and include the License file at LICENSE.txt.
 * If applicable, add the following below this CDDL HEADER, with the
 * fields enclosed by brackets "[]" replaced with your own identifying
 * information: Portions Copyright [yyyy] [name of copyright owner]
 *
 * CDDL HEADER END
 */

/*
 * Copyright (c) 2025, Jonathan S. Fisher.
 */
package org.opengrok.indexer.analysis.drools;

import java.util.HashSet;
import java.util.Set;

/**
 * Holds static hash set containing the Drools DRL keywords.
 * Based on Drools 8.x grammar.
 */
public class Consts {

    static final Set<String> kwd = new HashSet<>();
    static {
        // DRL structure keywords
        kwd.add("package");
        kwd.add("import");
        kwd.add("global");
        kwd.add("function");
        kwd.add("rule");
        kwd.add("query");
        kwd.add("declare");
        kwd.add("type");
        kwd.add("trait");
        kwd.add("extends");
        kwd.add("end");
        kwd.add("unit");

        // Rule structure
        kwd.add("when");
        kwd.add("then");

        // LHS keywords
        kwd.add("and");
        kwd.add("or");
        kwd.add("not");
        kwd.add("exists");
        kwd.add("forall");
        kwd.add("from");
        kwd.add("collect");
        kwd.add("accumulate");
        kwd.add("acc");
        kwd.add("eval");
        kwd.add("over");
        kwd.add("window");
        kwd.add("groupby");

        // Accumulate functions
        kwd.add("init");
        kwd.add("action");
        kwd.add("reverse");
        kwd.add("result");

        // RHS keywords - CRITICAL: these must be keywords, not symbols
        kwd.add("modify");
        kwd.add("update");
        kwd.add("insert");
        kwd.add("insertLogical");
        kwd.add("retract");
        kwd.add("delete");
        kwd.add("drools");
        kwd.add("kcontext");

        // Constraint operators
        kwd.add("matches");
        kwd.add("memberOf");
        kwd.add("contains");
        kwd.add("excludes");
        kwd.add("soundslike");
        kwd.add("soundsLike");
        kwd.add("str");
        kwd.add("in");

        // Temporal operators
        kwd.add("after");
        kwd.add("before");
        kwd.add("coincides");
        kwd.add("during");
        kwd.add("includes");
        kwd.add("finishes");
        kwd.add("finishedby");
        kwd.add("meets");
        kwd.add("metby");
        kwd.add("overlaps");
        kwd.add("overlappedby");
        kwd.add("starts");
        kwd.add("startedby");

        // Rule attributes - simple keywords
        kwd.add("salience");
        kwd.add("enabled");
        kwd.add("dialect");
        kwd.add("calendars");
        kwd.add("timer");
        kwd.add("duration");
        kwd.add("attributes");

        // Rule attributes - hyphenated (matched specially in lexer)
        kwd.add("ruleflow-group");
        kwd.add("agenda-group");
        kwd.add("activation-group");
        kwd.add("no-loop");
        kwd.add("auto-focus");
        kwd.add("lock-on-active");
        kwd.add("date-effective");
        kwd.add("date-expires");
        kwd.add("point");

        // Java/MVEL keywords that appear in DRL (RHS is Java/MVEL code)
        kwd.add("abstract");
        kwd.add("assert");
        kwd.add("boolean");
        kwd.add("break");
        kwd.add("byte");
        kwd.add("case");
        kwd.add("catch");
        kwd.add("char");
        kwd.add("class");
        kwd.add("const");
        kwd.add("continue");
        kwd.add("default");
        kwd.add("do");
        kwd.add("double");
        kwd.add("else");
        kwd.add("enum");
        kwd.add("false");
        kwd.add("final");
        kwd.add("finally");
        kwd.add("float");
        kwd.add("for");
        kwd.add("goto");
        kwd.add("if");
        kwd.add("implements");
        kwd.add("instanceof");
        kwd.add("int");
        kwd.add("interface");
        kwd.add("long");
        kwd.add("native");
        kwd.add("new");
        kwd.add("null");
        kwd.add("private");
        kwd.add("protected");
        kwd.add("public");
        kwd.add("return");
        kwd.add("short");
        kwd.add("static");
        kwd.add("strictfp");
        kwd.add("super");
        kwd.add("switch");
        kwd.add("synchronized");
        kwd.add("this");
        kwd.add("throw");
        kwd.add("throws");
        kwd.add("transient");
        kwd.add("true");
        kwd.add("try");
        kwd.add("void");
        kwd.add("volatile");
        kwd.add("while");
    }

    private Consts() {
    }

}
