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
 * Cross reference a Drools DRL file
 */

package org.opengrok.indexer.analysis.drools;

import java.io.IOException;
import org.opengrok.indexer.analysis.JFlexSymbolMatcher;
import org.opengrok.indexer.analysis.ScopeAction;
import org.opengrok.indexer.analysis.EmphasisHint;
import org.opengrok.indexer.util.StringUtils;
import org.opengrok.indexer.web.HtmlConsts;
%%
%public
%class DroolsXref
%extends JFlexSymbolMatcher
%unicode
%int
%char
%include ../CommonLexer.lexh
%include ../CommonXref.lexh
%{
  private int braceCount = 0;

  @Override
  public void reset() {
      super.reset();
      braceCount = 0;
  }

  @Override
  public void yypop() throws IOException {
      onDisjointSpanChanged(null, yychar);
      super.yypop();
  }

  protected void chkLOC() {
      switch (yystate()) {
          case COMMENT:
          case SCOMMENT:
              break;
          default:
              phLOC();
              break;
      }
  }
%}

File = [a-zA-Z]{FNameChar}* "." ([Jj][Aa][Vv][Aa] |
    [Pp][Rr][Oo][Pp][Ee][Rr][Tt][Ii][Ee][Ss] | [Pp][Rr][Oo][Pp][Ss] |
    [Xx][Mm][Ll] | [Cc][Oo][Nn][Ff] | [Tt][Xx][Tt] | [Hh][Tt][Mm][Ll]? |
    [Ii][Nn][Ii] | [Dd][Rr][Ll] | [Dd][Ii][Ff][Ff] | [Pp][Aa][Tt][Cc][Hh] |
    [Bb][Pp][Mm][Nn])

%state STRING COMMENT SCOMMENT QSTRING RULEDEF RHS ATTRSTRING

%include ../Common.lexh
%include ../CommonURI.lexh
%include ../CommonPath.lexh
%include Drools.lexh
%%
<YYINITIAL>{
    \{     { chkLOC(); onScopeChanged(ScopeAction.INC, yytext(), yychar); }
    \}     { chkLOC(); onScopeChanged(ScopeAction.DEC, yytext(), yychar); }
    \;     { chkLOC(); onScopeChanged(ScopeAction.END, yytext(), yychar); }
    
    /* Rule definition start - switch to RULEDEF to capture name */
    "rule" {WhspChar}* \" {
        chkLOC();
        String match = yytext();
        int quoteIdx = match.indexOf('"');
        // Output "rule" as keyword (will be bold via onFilteredSymbolMatched)
        onFilteredSymbolMatched("rule", yychar, Consts.kwd);
        // Output whitespace between rule and quote
        if (quoteIdx > 4) {
            onNonSymbolMatched(match.substring(4, quoteIdx), yychar + 4);
        }
        // Output opening quote
        onNonSymbolMatched("\"", yychar + quoteIdx);
        yypush(RULEDEF);
        onDisjointSpanChanged(HtmlConsts.STRING_CLASS, yychar + quoteIdx + 1);
    }
    
    /* Query definition start */
    "query" {WhspChar}* \" {
        chkLOC();
        String match = yytext();
        int quoteIdx = match.indexOf('"');
        onFilteredSymbolMatched("query", yychar, Consts.kwd);
        if (quoteIdx > 5) {
            onNonSymbolMatched(match.substring(5, quoteIdx), yychar + 5);
        }
        onNonSymbolMatched("\"", yychar + quoteIdx);
        yypush(RULEDEF);
        onDisjointSpanChanged(HtmlConsts.STRING_CLASS, yychar + quoteIdx + 1);
    }
    
    /* Hyphenated keywords followed by quoted string (attribute values) */
    {HyphenatedKeyword} {WhspChar}* \" {
        chkLOC();
        String match = yytext();
        int quoteIdx = match.indexOf('"');
        String keyword = match.substring(0, match.indexOf(' ') > 0 ? match.indexOf(' ') : quoteIdx).trim();
        // Output keyword as bold
        onFilteredSymbolMatched(keyword, yychar, Consts.kwd);
        // Output whitespace
        int kwLen = keyword.length();
        if (quoteIdx > kwLen) {
            onNonSymbolMatched(match.substring(kwLen, quoteIdx), yychar + kwLen);
        }
        // Output opening quote and switch to ATTRSTRING (no path matching)
        onNonSymbolMatched("\"", yychar + quoteIdx);
        yypush(ATTRSTRING);
        onDisjointSpanChanged(HtmlConsts.STRING_CLASS, yychar + quoteIdx + 1);
    }
    
    /* Hyphenated keywords without string value */
    {HyphenatedKeyword} {
        chkLOC();
        onFilteredSymbolMatched(yytext(), yychar, Consts.kwd);
    }
    
    /* Enter RHS mode after "then" keyword - must be before {Identifier} */
    "then" {
        chkLOC();
        onFilteredSymbolMatched(yytext(), yychar, Consts.kwd);
        braceCount = 0;
        yypush(RHS);
    }
    
    /* Null-safe dereference operator */
    {NullSafeOp} {
        chkLOC();
        onNonSymbolMatched(yytext(), yychar);
    }
    
    /* Drools variable: $varName */
    {DroolsVariable} {
        chkLOC();
        String match = yytext();
        // Output $ as plain text
        onNonSymbolMatched("$", yychar);
        // Output variable name as symbol (for searching)
        String varName = match.substring(1);
        onFilteredSymbolMatched(varName, yychar + 1, Consts.kwd);
    }
    
    /* Regular identifier - keywords will be bold, others as links */
    {Identifier} {
        chkLOC();
        String id = yytext();
        onFilteredSymbolMatched(id, yychar, Consts.kwd);
    }

    "<" ({File}|{FPath}) ">" {
        chkLOC();
        onNonSymbolMatched("<", yychar);
        String path = yytext();
        path = path.substring(1, path.length() - 1);
        onFilelikeMatched(path, yychar + 1);
        onNonSymbolMatched(">", yychar + 1 + path.length());
    }

    {Number} {
        chkLOC();
        onDisjointSpanChanged(HtmlConsts.NUMBER_CLASS, yychar);
        onNonSymbolMatched(yytext(), yychar);
        onDisjointSpanChanged(null, yychar + yylength());
    }
    
    {TimeInterval} {
        chkLOC();
        onDisjointSpanChanged(HtmlConsts.NUMBER_CLASS, yychar);
        onNonSymbolMatched(yytext(), yychar);
        onDisjointSpanChanged(null, yychar + yylength());
    }

    \" {
        chkLOC();
        yypush(STRING);
        onDisjointSpanChanged(HtmlConsts.STRING_CLASS, yychar);
        onNonSymbolMatched(yytext(), yychar);
    }
    \' {
        chkLOC();
        yypush(QSTRING);
        onDisjointSpanChanged(HtmlConsts.STRING_CLASS, yychar);
        onNonSymbolMatched(yytext(), yychar);
    }
    "/*" {
        yypush(COMMENT);
        onDisjointSpanChanged(HtmlConsts.COMMENT_CLASS, yychar);
        onNonSymbolMatched(yytext(), yychar);
    }
    "//" {
        yypush(SCOMMENT);
        onDisjointSpanChanged(HtmlConsts.COMMENT_CLASS, yychar);
        onNonSymbolMatched(yytext(), yychar);
    }
}

<RULEDEF> {
    /* Rule/query name inside quotes - make it a searchable symbol */
    [^\"\n]+ {
        chkLOC();
        String ruleName = yytext();
        onFilteredSymbolMatched(ruleName, yychar, Consts.kwd);
    }
    
    \" {
        onNonSymbolMatched(yytext(), yychar);
        yypop();
    }
    
    {EOL} {
        onEndOfLineMatched(yytext(), yychar);
        yypop();
    }
}

<ATTRSTRING> {
    /* Attribute string content - just output as string, no path matching */
    [^\"\n]+ {
        chkLOC();
        onNonSymbolMatched(yytext(), yychar);
    }
    
    \" {
        onNonSymbolMatched(yytext(), yychar);
        yypop();
    }
    
    {EOL} {
        onEndOfLineMatched(yytext(), yychar);
        yypop();
    }
}

<RHS> {
    /* Track brace nesting for modify/insert blocks */
    \{ { 
        chkLOC(); 
        braceCount++;
        onScopeChanged(ScopeAction.INC, yytext(), yychar); 
    }
    \} { 
        chkLOC(); 
        braceCount--;
        onScopeChanged(ScopeAction.DEC, yytext(), yychar); 
    }
    \; { chkLOC(); onScopeChanged(ScopeAction.END, yytext(), yychar); }
    
    /* Null-safe dereference operator */
    {NullSafeOp} {
        chkLOC();
        onNonSymbolMatched(yytext(), yychar);
    }
    
    /* Drools variable reference in RHS */
    {DroolsVariable} {
        chkLOC();
        String match = yytext();
        onNonSymbolMatched("$", yychar);
        String varName = match.substring(1);
        onFilteredSymbolMatched(varName, yychar + 1, Consts.kwd);
    }
    
    /* Exit RHS on "end" keyword (only when not inside braces) */
    "end" {
        chkLOC();
        if (braceCount <= 0) {
            onFilteredSymbolMatched(yytext(), yychar, Consts.kwd);
            yypop();
        } else {
            // Inside braces, "end" might be a variable name
            onFilteredSymbolMatched(yytext(), yychar, Consts.kwd);
        }
    }
    
    /* Regular identifier in RHS - Java/MVEL code */
    {Identifier} {
        chkLOC();
        String id = yytext();
        onFilteredSymbolMatched(id, yychar, Consts.kwd);
    }

    {Number} {
        chkLOC();
        onDisjointSpanChanged(HtmlConsts.NUMBER_CLASS, yychar);
        onNonSymbolMatched(yytext(), yychar);
        onDisjointSpanChanged(null, yychar + yylength());
    }

    \" {
        chkLOC();
        yypush(STRING);
        onDisjointSpanChanged(HtmlConsts.STRING_CLASS, yychar);
        onNonSymbolMatched(yytext(), yychar);
    }
    \' {
        chkLOC();
        yypush(QSTRING);
        onDisjointSpanChanged(HtmlConsts.STRING_CLASS, yychar);
        onNonSymbolMatched(yytext(), yychar);
    }
    "/*" {
        yypush(COMMENT);
        onDisjointSpanChanged(HtmlConsts.COMMENT_CLASS, yychar);
        onNonSymbolMatched(yytext(), yychar);
    }
    "//" {
        yypush(SCOMMENT);
        onDisjointSpanChanged(HtmlConsts.COMMENT_CLASS, yychar);
        onNonSymbolMatched(yytext(), yychar);
    }
}

<STRING> {
    \\[\"\\] { chkLOC(); onNonSymbolMatched(yytext(), yychar); }
    \" {
        chkLOC();
        onNonSymbolMatched(yytext(), yychar);
        yypop();
    }
}

<QSTRING> {
    \\[\'\\] { chkLOC(); onNonSymbolMatched(yytext(), yychar); }
    \' {
        chkLOC();
        onNonSymbolMatched(yytext(), yychar);
        yypop();
    }
}

<COMMENT> {
    "*/" {
        onNonSymbolMatched(yytext(), yychar);
        yypop();
    }
}

<SCOMMENT> {
    {WhspChar}*{EOL} {
        yypop();
        onEndOfLineMatched(yytext(), yychar);
    }
}


<YYINITIAL, STRING, COMMENT, SCOMMENT, QSTRING, RULEDEF, RHS, ATTRSTRING> {
    {WhspChar}*{EOL} { onEndOfLineMatched(yytext(), yychar); }
    [[\s]--[\n]] { onNonSymbolMatched(yytext(), yychar); }
    [^\n] { chkLOC(); onNonSymbolMatched(yytext(), yychar); }
}

<STRING, COMMENT, SCOMMENT, QSTRING, RHS> {
    {FPath} {
        chkLOC();
        onPathlikeMatched(yytext(), '/', false, yychar);
    }

    {File} {
        chkLOC();
        String path = yytext();
        onFilelikeMatched(path, yychar);
    }

    {FNameChar}+ "@" {FNameChar}+ "." {FNameChar}+ {
        chkLOC();
        onEmailAddressMatched(yytext(), yychar);
    }
}

<STRING, SCOMMENT, QSTRING> {
    {BrowseableURI} {
        chkLOC();
        onUriMatched(yytext(), yychar);
    }
}

<COMMENT> {
    {BrowseableURI} {
        onUriMatched(yytext(), yychar, StringUtils.END_C_COMMENT);
    }
}
