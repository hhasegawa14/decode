################################
# ファイル操作クラス
################################
class FileUtil
    def initialize()
    end

    #######################################
    # ファイル読込処理
    # 引数  ：fileName 読込ファイル名
    # 戻り値：Array[行]=ファイル１行のデータ
    #######################################
    def readArray( fileName )
        # ファイルデータ格納用連想配列初期化
        inputList =  Array.new

        # ファイルオープン
        lineNo = 0
        io =  File.open( fileName, "r") do |io|
            while 
                # 1行取得
                lineData = io.gets
                # 改行を消す
                lineData = lineData.chomp
                # 1行取得
                inputList[ lineNo ] = lineData
                # 行番号をインクリメント
                lineNo   += 1
            end
        end
        inputList
    end

end