################################
# 復号化クラス
################################
class EncodeWord
    def initialize()
        @dictWordList    = Hash.new{ |hash,key| hash[key] = {} } # PHP風の連想配列で使えるようにする
        @inputWordList   = Hash.new{ |hash,key| hash[key] = {} } # PHP風の連想配列で使えるようにする
        @inputWordListS  = Hash.new
        @covWordMaster   = Hash.new{ |hash,key| hash[key] = {} } # PHP風の連想配列で使えるようにする
        @decodeAnaList   = Hash.new{ |hash,key| hash[key] = {} } # PHP風の連想配列で使えるようにする
        @encodeWordKind  = Hash.new
        @encodeExecWords = Hash.new
        
    end

    #################################################################
    # 復号テーブルを展開する
    ################################################################
    def execDecode()
        # 全データ読込
        @inputWordListS.each{|words|
            # 変数初期化
            orgWords = ""
            wordNum  = 0
            convFlg  = false
            # 文字単位でループ
            words[0].chars.each{|word|
                # 復号テーブルと合致するか確認
                if @covWordMaster.has_key?( word )
                    # 復号処理を実行
                    orgWords += @covWordMaster[ word ]
                    # 復号された単語フラグを設定
                    convFlg = true
                    # 復号解析用配列に設定
                    # Hash[変換前単語][文字位置=>文字]
                    @decodeAnaList[ words[0] ][wordNum] = @covWordMaster[ word ]
                else 
                    # 元の文字をそのまま設定
                    orgWords += word
                end
                wordNum += 1
            }
        }
    end

    #################################################################
    # 復号済みのデータから再度復号可能な単語があるか調べる
    # 同一の文字数の単語から復号されたアルファベットの位置で合致し
    # 1パターンに絞り込めれば復号可能な単語とする
    ################################################################
    def execAnalysis()
        convList = Hash.new
        @decodeAnaList.each{|decodeAnaWords|
            # Hash[文字位置=>文字]
            wordSize = decodeAnaWords[0].size
            matchEndFlgList   = Hash.new
            matchWordList     = Hash.new
            decodeAnaWordsNum = decodeAnaWords[1].size
            ###############################################
            # 単語毎に復号できている文字の個数分照合する
            ###############################################
            decodeAnaWords[1].each{|anaWordHash|
                # 既に復号を終えている単語は照合の必要なし
                if @encodeExecWords.has_key?(decodeAnaWords[0])
                   next
               end
                # 単語がすべて復号されている場合は照合の必要無し
                if decodeAnaWords[0].size == decodeAnaWords[1].size
                    next
                end
               ############################################
                # 辞書の中から同一の文字数の単語を照合する
                ############################################
                matchCount = 0
                @dictWordList[ wordSize ].each{|dictWords|

                    ###########################################
                    # 複数復号できている文字がある場合
                    # 全て合致出来ていなければ照合処理を終了
                    ###########################################
                    if matchEndFlgList[ dictWords ] == true
                        next
                    end
                    # アルファベットの場所が一致している単語を探す
                    targetWord = dictWords[1][ anaWordHash[0], 1 ]
                    if targetWord == anaWordHash[1]
                        matchCount += 1
                        matchWordList[ dictWords[1] ] = decodeAnaWords[0]
                    # 照合失敗
                    else
                        if matchWordList.key?( dictWords[1] )
                            matchWordList.delete( dictWords[1] ) 
                        end
                        matchEndFlgList[ dictWords[1] ] = true
                   end
                }

                # 復号できている全ての文字が一致した単語が
                # １パターンの場合は復号可能な単語に設定
                if matchWordList.size == 1
                    matchWordList.each{|matchWord, encodeWord|
                        convList[ matchWord ] = encodeWord
                        @encodeExecWords[ encodeWord ] = true
                    }
                end
            }
        }
        convList
    end

    #################################################################
    # 単語文字数毎にデータを作成する
    # 引数  ：inputList[行]=行データ
    # 戻り値：Hash[単語文字数][ 単語文字数毎の単語の数 => 単語 ]
    ################################################################
    def setWordNumArray( inputList )
        wordNumList = Hash.new{ |hash,key| hash[key] = {} }
        # 全データ読込
        inputList.each{|rowList|
            # 英語スペース以外を削除
            rowList = rowList.gsub(/[^A-Za-z|\s]/, "")
            # 単語単位に配列へ格納(空白区切り)
            wordList = rowList.split
            # 単語単位でループ
            wordList.each{|word|
                # 単語の文字数を設定
                wordSize = word.size
                # 配列に同一の文字列が存在しない場合は0
                if wordNumList[ wordSize ].nil? then
                    wordNumCount = 0 
                else
                    wordNumCount = wordNumList[ wordSize ].size
                end
                wordNumList[ wordSize ][ wordNumCount ] = word
            }
        }
        wordNumList
    end

    ################################################################
    # 辞書の中から同一文字数の単語が1種類しか存在しない単語を抽出
    # 戻り値：復号特定できた単語 Hash[ 辞書の単語 => 入力値の単語 ] 
    ################################################################
    def getDictWordNumCountOne( )
        # 変数宣言
        wordNumCountOneList = Hash.new
        @dictWordList.each{|wordNumCountList|
            # 同一文字数の単語は1種類か
            if wordNumCountList[1].size == 1
                wordSize = wordNumCountList[1][0].size
             next if @inputWordList[ wordSize ][0].nil?
             wordNumCountOneList[ wordNumCountList[1][0] ] =  @inputWordList[ wordSize ][0]
            end
        }
        wordNumCountOneList
    end
    #################################################################
    # アルファベット毎の復号テーブルを登録
    # Hash[ 暗号化されたアルファベット =>元のアルファベット ]形式で登録
    # 入力値：復号特定できた単語 Hash[ 辞書の単語 => 入力値の単語 ] 
    ################################################################
    def setConvMasterHash( encodeWordsList )
        covWordList = Hash.new{ |hash,key| hash[key] = {} }

        encodeWordsList.each{|convDicWords, convInputWords|
            wordCount   = 0;
            # 文字数を取得
            wordSize  = convDicWords.size
            # 文字が1文字の場合は復号ルールに設定
            if wordSize == 1
                # 復号ルール登録
                @covWordMaster[ convInputWords ] = convDicWords
            else
                # 文字が複数の場合は１文字づつ変換テーブルに登録
                convDicWords.chars.each{|convDictWord|
                    # 復号ルール登録 小文字で登録
                    convDictWord.downcase
                    @covWordMaster[ convInputWords[ wordCount ].downcase ] = convDictWord.downcase
                    wordCount += 1
                }
           end
        }
    end
    #################################################################
    # エンコードが終了したかチェックする
    # Hash[ 暗号化されたアルファベット =>元のアルファベット ]形式で登録
    # 戻り値：復号特定できた単語 Hash[ 辞書の単語 => 入力値の単語 ] 
    ################################################################
    def chkEncodeEnd()
        if @encodeWordKind.size == @covWordMaster.size
            true
        else
            false
        end
    end
    #################################################################
    # エンコード処理を行う
    # 入力値：暗号化された文字列
    # 入力値：復号した文字列
    ################################################################
    def execEncode( inputList )
        decodeWords = "";
        print decodeWords
        inputList.each{|rowlist|
            rowlist.chars.each{|inputWord|
                # 変換する
                # 復号テーブルにあるかを確認
                inputWordD = inputWord.downcase
                if @covWordMaster.has_key?( inputWordD )
                    decodeWord = @covWordMaster[ inputWordD ]
                    # 元の文字が大文字の場合は大文字に変換する
                    decodeWord = decodeWord.upcase if inputWord =~ /[A-Z]/
                    decodeWords += decodeWord
                else
                    decodeWords += inputWord
                end
            }
            decodeWords += "\n"
        }
        decodeWords
    end
    #################################################################
    # 入力データの中から重複単語を除いたデータを作成する
    ################################################################
    def overlapWordDel()
        @inputWordList.each{|rowList|
            rowList[1].each_with_index{|words|
                # keyに単語を設定して、重複をなくす
                @inputWordListS[words[1]] = false
                # 復号に必要なアルファベットの総数を設定
                # 復号しなければならないアルファベットを抽出する
                words[1].chars.each{|word|
                    # 小文字で登録する
                    wordD = word.downcase
                    @encodeWordKind[ wordD ] = false
                }
            }
        }
    end
    #################################################################
    # 入力データを登録する
    # 入力値：入力データ
    ################################################################
    def setInputWordList( inputWordList )
        @inputWordList = setWordNumArray( inputWordList )
    end

    #################################################################
    # 辞書データを登録する
    # 入力値：辞書データ
    ################################################################
    def setDictWordList( dictWordList )
        @dictWordList  = setWordNumArray( dictWordList )
    end
    
end