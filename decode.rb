#!ruby
###########################
# 問題3
###########################
###########################
# 初期設定
###########################
# 外部クラス読込設定
require './lib/FileUtil.rb'  # ファイル操作クラス読込
require './lib/EncodeWord.rb' # 配列操作クラス読込

# 引数チェック
if  ARGV.size != 2
    print "引数に入力ファイル名と辞書ファイル名を指定してください\n"
    print "ruby q3.rb 入力ファイル名 辞書ファイル名\n"
    exit
end
# ファイル名を設定
inputFileName = ARGV[0]
dictFileName  = ARGV[1]

###########################
# ファイル読込
###########################
# クラス読込
cFileUtil = FileUtil.new
# Array[行]=ファイル１行のデータ
inputWordList = cFileUtil.readArray( inputFileName ) # 入力データ読込
dictWordList  = cFileUtil.readArray( dictFileName )  # 辞書データ読込

###########################
# 複合ルールを調べる
###########################
# 単語単位で整理する
# クラス読込
cEncodeWord = EncodeWord.new()

######################################################
# ファイルからデータを取得する
######################################################
# 単語文字数毎にデータを作成する
# Hash[単語文字数][ 単語文字数毎の単語の数 => 単語 ]
cEncodeWord.setInputWordList( inputWordList )
cEncodeWord.setDictWordList( dictWordList )

##########################################################
# 復号パターン特定用にデータを加工する
##########################################################
cEncodeWord.overlapWordDel
        
##########################################################
# 復号パターン解析処理
##########################################################
convWordList = Hash.new{ |hash,key| hash[key] = {} }

# 単語の同一文字数の数による解析
# 文字数の単語が1種類しか存在しない単語を取得
dictWordNumCountOneList = cEncodeWord.getDictWordNumCountOne()
# 特定できたアルファベットを復号テーブルに登録する
cEncodeWord.setConvMasterHash( dictWordNumCountOneList )
# 復号テーブルを展開する
cEncodeWord.execDecode()

# 全ての復号アルファベットが特定できるまで
# 特定出来たアルファベットの展開、新たな復号パターン抽出を繰り返す
loop{
    # 全ての文字が変換されていれば表示して終了
    encodeEndFlg = cEncodeWord.chkEncodeEnd
    if encodeEndFlg == true
       # 復号化処理実行 結果表示
       print cEncodeWord.execEncode( inputWordList )
       break
    end

    # 復号した状態で辞書と比較する
    # 合致単語数が１種類の場合は復号特定
    convList = cEncodeWord.execAnalysis
    # 新たな復号パターンが抽出できなかった場合は終了
    if convList.size == 0
        print "復号できませんでした\n"
        break;
    end

    # 新たに発見した復号情報を展開する
    # 特定できたアルファベットを復号テーブルに登録する
    convWordList = cEncodeWord.setConvMasterHash( convList )
}


