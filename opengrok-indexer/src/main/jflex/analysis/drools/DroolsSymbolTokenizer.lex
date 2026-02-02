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
 * Copyright (c) 2026, Jonathan S. Fisher.
 * Gets Drools DRL symbols - ignores comments, strings, keywords
 */

package org.opengrok.indexer.analysis.drools;

import org.opengrok.indexer.analysis.JFlexSymbolMatcher;
%%
%public
%class DroolsSymbolTokenizer
%extends JFlexSymbolMatcher
%unicode
%buffer 32766
%int
%include ../CommonLexer.lexh
%char

%state STRING COMMENT SCOMMENT QSTRING RULEDEF RHS ATTRSTRING

%include ../Common.lexh
%include Drools.lexh
%%

<YYINITIAL> {
    /* Rule definition - capture the rule name */
    "rule" {WhspChar}* \" {
        yybegin(RULEDEF);
    }
    
    /* Query definition */
    "query" {WhspChar}* \" {
        yybegin(RULEDEF);
    }
    
    /* Hyphenated keywords followed by quoted string - skip to ATTRSTRING */
    {HyphenatedKeyword} {WhspChar}* \" {
        yybegin(ATTRSTRING);
    }
    
    /* Hyphenated keywords without string - just skip */
    {HyphenatedKeyword} { }
    
    /* Function definitions - capture function name */
    "function" {WhspChar}+ {Identifier} {WhspChar}+ {Identifier} {WhspChar}* \( {
        String match = yytext();
        String[] parts = match.trim().split("\\s+");
        if (parts.length >= 3) {
            String funcName = parts[2];
            // Remove trailing ( if present
            if (funcName.endsWith("(")) {
                funcName = funcName.substring(0, funcName.length() - 1);
            }
            if (!Consts.kwd.contains(funcName)) {
                onSymbolMatched(funcName, yychar);
                return yystate();
            }
        }
    }
    
    /* Global variable declarations */
    "global" {WhspChar}+ {Identifier} {WhspChar}+ {Identifier} {
        String match = yytext();
        String[] parts = match.trim().split("\\s+");
        if (parts.length >= 3) {
            String typeName = parts[1];
            String varName = parts[2];
            if (!Consts.kwd.contains(typeName)) {
                onSymbolMatched(typeName, yychar);
            }
            if (!Consts.kwd.contains(varName)) {
                onSymbolMatched(varName, yychar);
                return yystate();
            }
        }
    }
    
    /* Enter RHS after "then" keyword - must be before {Identifier} */
    "then" { yybegin(RHS); }
    
    /* Null-safe dereference operator - skip it */
    {NullSafeOp} { }
    
    /* Drools variable: $varName */
    {DroolsVariable} {
        String id = yytext().substring(1); // remove $ prefix
        if (!Consts.kwd.contains(id)) {
            onSymbolMatched(id, yychar);
            return yystate();
        }
    }
    
    /* Regular identifier */
    {Identifier} {
        String id = yytext();
        if (!Consts.kwd.contains(id)) {
            onSymbolMatched(id, yychar);
            return yystate();
        }
    }

    {Number}        {}
    {TimeInterval}  {}

    \"     { yybegin(STRING); }
    \'     { yybegin(QSTRING); }
    "/*"   { yybegin(COMMENT); }
    "//"   { yybegin(SCOMMENT); }
}

<RULEDEF> {
    /* Capture the rule/query name inside quotes */
    [^\"\n]+ {
        String ruleName = yytext();
        onSymbolMatched(ruleName, yychar);
        return yystate();
    }
    \"     { yybegin(YYINITIAL); }
    {EOL}  { yybegin(YYINITIAL); }
}

<ATTRSTRING> {
    /* Attribute string content - just skip, don't index */
    [^\"\n]+ { }
    \"     { yybegin(YYINITIAL); }
    {EOL}  { yybegin(YYINITIAL); }
}

<RHS> {
    /* Null-safe dereference operator - skip it */
    {NullSafeOp} { }
    
    /* Drools variable in RHS */
    {DroolsVariable} {
        String id = yytext().substring(1);
        if (!Consts.kwd.contains(id)) {
            onSymbolMatched(id, yychar);
            return yystate();
        }
    }
    
    /* Regular identifier in RHS (Java/MVEL code) */
    {Identifier} {
        String id = yytext();
        if (!Consts.kwd.contains(id)) {
            onSymbolMatched(id, yychar);
            return yystate();
        }
    }
    
    {Number}   {}
    \"         { yybegin(STRING); }
    \'         { yybegin(QSTRING); }
    "/*"       { yybegin(COMMENT); }
    "//"       { yybegin(SCOMMENT); }
    
    /* Exit RHS on "end" keyword */
    "end"      { yybegin(YYINITIAL); }
}

<STRING> {
    \\[\"\\]   {}
    \"         { yybegin(YYINITIAL); }
}

<QSTRING> {
    \\[\'\\]   {}
    \'         { yybegin(YYINITIAL); }
}

<COMMENT> {
    "*/"       { yybegin(YYINITIAL); }
}

<SCOMMENT> {
    {EOL}      { yybegin(YYINITIAL); }
}

<YYINITIAL, STRING, COMMENT, SCOMMENT, QSTRING, RULEDEF, RHS, ATTRSTRING> {
    {WhspChar}+    {}
    [^]            {}
}
