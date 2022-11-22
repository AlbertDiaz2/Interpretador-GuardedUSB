# Universidad Simón Bolívar
# CI-3725 Traductores e Interpretadores
# GuardedUSB Etapa 4
# @author: Albert Díaz     11-10278
# @author: Moisés González 11-10406
# @date: DICIEMBRE-2019
# @file: lexer.rb

require 'strscan'

class Lexer
    @@column = 1
    @@row = 1

    TOKENS = {

        # Ignorar
        /\s/                        => :ignore,
        /\/\/.*/                    => :ignore,
        # Palabras Reservadas
        /\bdeclare\b/               => :TkDeclare,
        /\bread\b/                  => :TkRead,
        /\bprint\b/                 => :TkPrint,
        /\bprintln\b/               => :TkPrintln,
        /\bif\b/                    => :TkIf,
        /\bfi\b/                    => :TkFi,
        /\bfor\b/                   => :TkFor,
        /\brof\b/                   => :TkRof,
        /\bin\b/                    => :TkIn,
        /\bto\b/                    => :TkTo,
        /\bdo\b/                    => :TkDo,
        /\bod\b/                    => :TkOd,
        /\barray\b/                 => :TkArray,
        /\btrue\b/                  => :TkTrue,
        /\bfalse\b/                 => :TkFalse,
        /\bbool\b/                  => :TkBool,
        /\bint\b/                   => :TkInt,
        /\batoi\b/                  => :TkAtoi,
        /\bsize\b/                  => :TkSize,
        /\bmax\b/                   => :TkMax,
        /\bmin\b/                   => :TkMin,

        # Constantes
        /\b\d+\b/                   => :TkNum,

        /\b[A-Za-z][A-Za-z0-9_]*\b/ => :TkId,
        /"[^"\\]*(?:\\.[^"\\]*)*"/  => :TkString,
        # /"[^\\"]*"/           => :TkString,

        # Separadores
        /\|\[/                      => :TkOBlock,
        /\]\|/                      => :TkCBlock,
        /\.\./                      => :TkSoForth,
        /,/                         => :TkComma,
        /\(/                        => :TkOpenPar,
        /\)/                        => :TkClosePar,
        /:=/                        => :TkAsig,
        /;/                         => :TkSemicolon,
        /-->/                       => :TkArrow,
        /\[\]/                      => :TkGuard,


        # Operadores
        /\+/                        => :TkPlus,
        /-/                         => :TkMinus,
        /\*/                        => :TkMult,
        /%/                         => :TkMod,
        /\\\//                      => :TkOr,
        /\/\\/                      => :TkAnd,
        /%/                         => :TkMod,
        /\//                        => :TkDiv,
        /!=/                        => :TkNEqual,
        /!/                         => :TkNot,
        /<=/                        => :TkLeq,
        />=/                        => :TkGeq,
        /</                         => :TkLess,
        />/                         => :TkGreater,
        /==/                        => :TkEqual,
        /\[/                        => :TkOBracket,
        /\]/                        => :TkCBracket,
        /:/                         => :TkTwoPoints,
        /\|\|/                      => :TkConcat,
    }

    ERRORS = {
        /"(\\"|[^\n\\"])*$/  => :EOL,
        /./                  => :unexpected,
    }

    def lex(string)
        scanner = StringScanner.new(string)
        lists = { :token_list => [], :error_list => [] }

        until scanner.eos?
            type, info = next_token(scanner)
            lists[type] << info if type != nil
        end

        if !lists[ :error_list ].empty?
          imprimir_tokens(lists)
          exit 1
        end

        return lists[:token_list]
    end

    def next_token(scanner)
        TOKENS.each do |reg,tk|
            value = scanner.scan(reg)
            if value
                if value.include? "\n"
                    @@row += value.count("\n")
                    ultimo_salto = value.rindex("\n") + 1
                    # Contar caracteres despues del ultimo salto de column
                    @@column = value[ultimo_salto..-1].length
                end
                if tk == :ignore
                    @@column += value.length
                    return nil
                end
                token_info = { token: tk, column: @@column, row: @@row, value: value }
                @@column += value.length
                return :token_list, token_info
            end
        end

        ERRORS.each do |reg, tk|
            value = scanner.scan(reg)
            if value
                @@column += value.length
                value = "EOL" if tk == :EOL
                error_info = {value: value, column: @@column, row: @@row}
                @@row += 1
                @@column = 0
                return :error_list, error_info
            end
        end
    end

    def imprimir_tokens(lists)
        if lists[:error_list].empty?
            lists[:token_list].each do |token_info|
                case token_info[:token]
                when :TkId, :TkNum
                    puts "#{token_info[:token]}(\"#{token_info[:value]}\") " +
                        "#{token_info[:row]} #{token_info[:column]}"
                when :TkString
                    puts "#{token_info[:token]}(#{token_info[:value]}) " +
                        "#{token_info[:row]} #{token_info[:column]}"
                when :ignore
                else
                    puts "#{token_info[:token]} " +
                        "#{token_info[:row]} #{token_info[:column]}"
                end
            end
        else
            lists[:error_list].each do |err|
                puts "Error: Unexpected #{err[:value]}"+
                    " in row #{err[:row]}, column #{err[:column]}"
            end
        end
    end
end
