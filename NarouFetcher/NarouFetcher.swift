//
//	NarouFetcher.swift
//	NarouFetcher
//
//  Created by Kaz Yoshikawa on 12/25/19.
//

import Foundation

extension String {
	var stringByDecodingNonLossyASCII: String {
		return self.cString(using: .utf8).flatMap({ String(cString: $0, encoding: .nonLossyASCII) }) ?? self
	}
}

public extension CustomStringConvertible {
	var xdescription: String { return self.description.stringByDecodingNonLossyASCII }
}

public struct NarouDate: CustomStringConvertible {
	public var year: Int
	public var month: Int
	public var day: Int
	public var hour: Int
	public var minute: Int
	public var second: Int
	public init?(year: Int, month: Int, day: Int, hour: Int, minute: Int, second: Int) {
		var component = DateComponents()
		component.year = year
		component.month = month
		component.day = day
		component.hour = hour
		component.minute = minute
		component.second = second
		guard component.isValidDate else { return nil }
		self.year = year
		self.month = month
		self.day = day
		self.hour = hour
		self.minute = minute
		self.second = second
	}
	public init?(string: String) {
		let formatter = DateFormatter()
		formatter.locale = Locale(identifier: "en_US_POSIX")
		formatter.dateFormat = "yyyy'-'MM'-'dd HH':'mm':'ss"
		guard let date = formatter.date(from: string) else { return nil }
		let calendar = Calendar(identifier: .gregorian)
		let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
		if let year = components.year, let month = components.month, let day = components.day,
		   let hour = components.hour, let minute = components.minute, let second = components.second {
			self.year = year
			self.month = month
			self.day = day
			self.hour = hour
			self.minute = minute
			self.second = second
		}
		else { return nil }
	}
	public var date: Date? {
		let calendar = Calendar(identifier: .gregorian)
		var components = DateComponents()
		components.year = self.year
		components.month = self.month
		components.day = self.day
		components.hour = self.hour
		components.minute = self.minute
		components.second = self.second
		components.calendar = calendar
		return components.date
	}
	public var description: String {
		let calendar = Calendar(identifier: .gregorian)
		guard let date = self.date else { fatalError() }
		let formatter = DateFormatter()
		formatter.locale = Locale(identifier: "ja_JP")
		formatter.dateFormat = "yyyy'-'MM'-'dd HH':'mm':'ss"
		formatter.calendar = calendar
		return formatter.string(from: date)
	}
}

public protocol NarouQueryParameter {
	var name: String { get }
	var value: String { get }
}

open class NarouFetcher {
	public static let shared = NarouFetcher()
	private init() {
	}
	fileprivate static let api = "https://api.syosetu.com/novelapi/api/"
	public enum ParameterKey: String {
		case 出力形式 = "out"  // 出力形式をyamlまたはjsonまたはphpを指定。未指定時はYAMLになる。
		case 出力項目指定 = "of"  // 出力する項目を個別に指定できます。未指定時は全項目出力されます。 転送量軽減のため、このパラメータの使用が推奨されます。 複数項目を出力する場合は-で区切ってください。
		case 最大出力数 = "lim"  // 最大出力数を指定できます。最低1、最高500です。半角数字で指定してください。指定しない場合は20件になります。
		case 表示開始位置指定 = "st"  // 表示開始位置の指定です。半角数字で指定してください。 たとえば全部で10作品あるとして、3作品目以降の小説情報を取得したい場合は3と指定してください。
		case 出力順序 = "order"  // 出力順序を指定できます。指定しない場合は新着更新順となります。
		// 検索単語指定
		case 単語指定 = "word"  // 単語を指定できます。文字コードはUTF-8でURLエンコードしてください。 半角または全角スペースで区切るとAND抽出になります。部分一致でHITします。
		case 単語除外 = "notword"  // 含みたくない単語を指定できます。文字コードはUTF-8でURLエンコードしてください。 スペースで区切ることにより含ませない単語を増やせます。部分一致で除外されます。
		// 大分類
		case 大分類指定 = "biggenre"  // 大ジャンルを指定できます。ハイフン(-)記号で区切れば複数大ジャンルを一括抽出できます。
		case 大分類除外 = "notbiggenre"  // 大ジャンルを除外検索できます。ハイフン(-)記号で区切れば含ませたくない大ジャンルを増やせます。
		// ジャンル指定
		case ジャンル指定 = "genre" // 大ジャンルを指定できます。ハイフン(-)記号で区切れば複数大ジャンルを一括抽出できます。
		case ジャンル除外 = "notgenre" // 大ジャンルを除外検索できます。ハイフン(-)記号で区切れば含ませたくない大ジャンルを増やせます。
		// ユーザID指定
		case ユーザID指定 = "userid" // ユーザIDで抽出可能。ハイフン(-)記号で区切ればユーザIDのOR検索ができます。
		// 登録必須キーワード指定
		case R15指定 = "isr15" // 1を指定した場合、登録必須キーワードに「R15」が含まれている小説のみを抽出します。
		case ボーイズラブ指定 = "isbl" // 1を指定した場合、登録必須キーワードに「ボーイズラブ」が含まれている小説のみを抽出します。
		case ガールズラブ指定 = "isgl" // 1を指定した場合、登録必須キーワードに「ガールズラブ」が含まれている小説のみを抽出します。
		case 残酷な描写あり指定 = "iszankoku" // 1を指定した場合、登録必須キーワードに「残酷な描写あり」が含まれている小説のみを抽出します。
		case 異世界転生指定 = "istensei" // 1を指定した場合、登録必須キーワードに「異世界転生」が含まれている小説のみを抽出します。
		case 異世界転移指定 = "istenni" // 1を指定した場合、登録必須キーワードに「異世界転移」が含まれている小説のみを抽出します。
		case 異世界転生異世界転移指定 = "istt" // 1を指定した場合、登録必須キーワードに「異世界転生」または「異世界転移」が含まれている小説のみを抽出します。
		// 登録必須キーワード除外指定
		case R15除外 = "notr15" // 1を指定した場合、登録必須キーワードに「R15」が含まれている小説を除外し抽出します。
		case ボーイズラブ除外 = "notbl" // 1を指定した場合、登録必須キーワードに「ボーイズラブ」が含まれている小説を除外し抽出します。
		case ガールズラブ除外 = "notgl" // 1を指定した場合、登録必須キーワードに「ガールズラブ」が含まれている小説を除外し抽出します。
		case 残酷な描写あり除外 = "notzankoku" // 1を指定した場合、登録必須キーワードに「残酷な描写あり」が含まれている小説を除外し抽出します。
		case 異世界転生除外 = "nottensei" // 1を指定した場合、登録必須キーワードに「異世界転生」が含まれている小説を除外し抽出します。
		case 異世界転移除外 = "nottenni" // 1を指定した場合、登録必須キーワードに「異世界転移」が含まれている小説を除外し抽出します。
		// 文字数指定
		case minlen // 抽出する小説の最小文字数を指定できます。文字数とは小説から一部タグ記号(改ページ等)、ルビ、ルビのふりがな部分、みてみんの画像挿入コード、スペース、改行を抜いた値です。
		case maxlen // 抽出する小説の最大文字数。文字数とは小説から一部タグ記号(改ページ等)、ルビ、ルビのふりがな部分、みてみんの画像挿入コード、スペース、改行を抜いた値です。
		case length // 抽出する小説の文字数を指定できます。minlenまたはmaxlenと併用はできません。文字数とは小説から一部タグ記号(改ページ等)、ルビ、ルビのふりがな部分、みてみんの画像挿入コード、スペース、改行を抜いた値です。範囲指定する場合は、最小文字数と最大文字数をハイフン(-)記号で区切ってください。
		// 会話率指定
		case 会話率指定 = "kaiwaritu" // 抽出する小説の会話率を%単位で指定できます。範囲指定する場合は、最低数と最大数をハイフン(-)記号で区切ってください。
		// 挿絵数指定
		case sasie // 抽出する小説の挿絵の数を指定できます。範囲指定する場合は、最小数と最大数を-(ハイフン)記号で区切ってください。
		// 読了時間指定
		case 最低読了時間（分） = "mintime" // 抽出する小説の最低読了時間を分単位で指定できます。読了時間は小説文字数÷500を切り上げした数字です。
		case 最大読了時間（分） = "maxtime" // 抽出する小説の最大読了時間を分単位で指定できます。読了時間は小説文字数÷500を切り上げした数字です。
		case 読了時間（分） = "time" // 抽出する小説の読了時間を指定できます。mintimeまたはmaxtimeと併用はできません。読了時間は小説文字数÷500を切り上げした数字です。範囲指定する場合は、最小文字数と最大文字数をハイフン(-)記号で区切ってください。
		// 小説タイプ指定
		case 小説タイプ指定 = "type" // 小説タイプを指定できます。
		// Nコード指定
		case Nコード = "ncode" // Nコードで抽出可能。ハイフン(-)記号で区切ればNコードのOR検索ができます。開示設定が「検索除外中です」となっている作品は抽出できません。
		// 文体指定
		case 文体指定 = "buntai"
		// 連載停止中指定
		case 連載停止中指定 = "stop" // 連載停止中作品に関する指定ができます。
		// 最終掲載日指定
		case 最終掲載日指定 = "lastup" // 最終掲載日(general_lastup)で抽出できます。以下の文字列を指定できます。
			// thisweek：今週(日曜日の午前0時はじまり), lastweek：先週, sevenday：過去7日間(7日前の午前0時はじまり), thismonth：今月, lastmonth：先月
			// タイムスタンプで指定: 開始日と終了日をハイフン(-)記号で区切ることでUNIXタイムスタンプで抽出できます。UNIXタイムスタンプとは1970年1月1日からの通算秒数のことです。
		// ピックアップ指定
		case ピックアップ指定 = "ispickup" // 1を指定した場合、小説ピックアップの対象となっている小説のみを抽出します。
	}
	public enum 検索対象範囲: String {
		case タイトル = "title"  // (int) 1の場合はタイトルをwordとnotwordの抽出対象にします。
		case あらすじ = "ex"  // (int) 1の場合はあらすじをwordとnotwordの抽出対象にします。
		case キーワード = "keyword"  // (int) 1の場合はキーワードをwordとnotwordの抽出対象にします。
		case 作者名 = "wname"  // (int) 1の場合は作者名をwordとnotwordの抽出対象にします。
	}
	public enum 登録必須キーワード指定区分: String {
		case R15指定 // 1を指定した場合、登録必須キーワードに「R15」が含まれている小説のみを抽出します。
		case ボーイズラブ指定 // 1を指定した場合、登録必須キーワードに「ボーイズラブ」が含まれている小説のみを抽出します。
		case ガールズラブ指定 // 1を指定した場合、登録必須キーワードに「ガールズラブ」が含まれている小説のみを抽出します。
		case 残酷な描写あり指定 // 1を指定した場合、登録必須キーワードに「残酷な描写あり」が含まれている小説のみを抽出します。
		case 異世界転生指定 // 1を指定した場合、登録必須キーワードに「異世界転生」が含まれている小説のみを抽出します。
		case 異世界転移指定 // 1を指定した場合、登録必須キーワードに「異世界転移」が含まれている小説のみを抽出します。
		case 異世界転生異世界転移指定 // 1を指定した場合、登録必須キーワードに「異世界転生」または「異世界転移」が含まれている小説のみを抽出します。
		var key: ParameterKey {
			switch self {
			case .R15指定: return .R15指定
			case .ボーイズラブ指定: return .ボーイズラブ指定
			case .ガールズラブ指定: return .ガールズラブ指定
			case .残酷な描写あり指定: return .残酷な描写あり指定
			case .異世界転生指定: return .異世界転生指定
			case .異世界転移指定: return .異世界転移指定
			case .異世界転生異世界転移指定: return .異世界転生異世界転移指定
			}
		}
	}
	public enum 登録必須キーワード除外区分: String {
		case R15除外 = "notr15" // 1を指定した場合、登録必須キーワードに「R15」が含まれている小説を除外し抽出します。
		case ボーイズラブ除外 = "notbl" // 1を指定した場合、登録必須キーワードに「ボーイズラブ」が含まれている小説を除外し抽出します。
		case ガールズラブ除外 = "notgl" // 1を指定した場合、登録必須キーワードに「ガールズラブ」が含まれている小説を除外し抽出します。
		case 残酷な描写あり除外 = "notzankoku" // 1を指定した場合、登録必須キーワードに「残酷な描写あり」が含まれている小説を除外し抽出します。
		case 異世界転生除外 = "nottensei" // 1を指定した場合、登録必須キーワードに「異世界転生」が含まれている小説を除外し抽出します。
		case 異世界転移除外 = "nottenni" // 1を指定した場合、登録必須キーワードに「異世界転移」が含まれている小説を除外し抽出します。
		var key: ParameterKey {
			switch self {
			case .R15除外: return .R15除外
			case .ボーイズラブ除外: return .ボーイズラブ除外
			case .ガールズラブ除外: return .ガールズラブ除外
			case .残酷な描写あり除外: return .残酷な描写あり除外
			case .異世界転生除外: return .異世界転生除外
			case .異世界転移除外: return .異世界転移除外
			}
		}
	}
	fileprivate enum 出力形式: String {
		case yaml  // YAML形式
		case json  // JSON形式
		case php  // PHPのserialize()
		case atom  // Atomフィード
		case jsonp  // JSONP形式
	}
	public enum 出力順序: String, CaseIterable {
		case 新着更新順
		case ブックマーク数の多い順
		case レビュー数の多い順
		case 総合ポイントの高い順
		case 総合ポイントの低い順
		case 日間ポイントの高い順
		case 週間ポイントの高い順
		case 月間ポイントの高い順
		case 四半期ポイントの高い順
		case 年間ポイントの高い順
		case 感想の多い順
		case 評価者数の多い順
		case 評価者数の少ない順
		case 週間ユニークユーザの多い順  // 毎週火曜日早朝リセット　(前週の日曜日から土曜日分)
		case 小説本文の文字数が多い順
		case 小説本文の文字数が少ない順
		case 新着投稿順
		case 更新が古い順
		public var key: String {
			switch self {
			case .新着更新順: return "new"
			case .ブックマーク数の多い順: return "favnovelcnt"
			case .レビュー数の多い順: return "reviewcnt"
			case .総合ポイントの高い順: return "hyoka"
			case .総合ポイントの低い順: return "hyokaasc"
			case .日間ポイントの高い順: return "dailypoint"
			case .週間ポイントの高い順: return "weeklypoint"
			case .月間ポイントの高い順: return "monthlypoint"
			case .四半期ポイントの高い順: return "quarterpoint"
			case .年間ポイントの高い順: return "yearlypoint"
			case .感想の多い順: return "impressioncnt"
			case .評価者数の多い順: return "hyokacnt"
			case .評価者数の少ない順: return "hyokacntasc"
			case .週間ユニークユーザの多い順: return "weekly"  // 毎週火曜日早朝リセット　(前週の日曜日から土曜日分)
			case .小説本文の文字数が多い順: return "lengthdes"
			case .小説本文の文字数が少ない順: return "lengthasc"
			case .新着投稿順: return "ncodedesc"
			case .更新が古い順: return "old"
			}
		}
	}
	public enum 大分類: Int, CaseIterable {
		case 恋愛 = 1
		case ファンタジー = 2
		case 文芸 = 3
		case ＳＦ = 4
		case その他 = 99
		case ノンジャンル = 98
	}
	public enum ジャンル: Int, CaseIterable {
		case 異世界（恋愛） = 101
		case 現実世界（恋愛） = 102
		case ハイファンタジー = 201
		case ローファンタジー = 202
		case 純文学（文芸） = 301
		case ヒューマンドラマ（文芸） = 302
		case 歴史（文芸） = 303
		case 推理（文芸） = 304
		case ホラー（文芸） = 305
		case アクション（文芸） = 306
		case コメディー（文芸） = 307
		case VRゲーム（SF） = 401
		case 宇宙（SF） = 402
		case 空想科学（SF） = 403
		case パニック（SF） = 404
		case 童話（その他） = 9901
		case 詩（その他） = 9902
		case エッセイ（その他） = 9903
		case リプレイ（その他） = 9904
		case その他（その他） = 9999
		case ノンジャンル（ノンジャンル） = 9801
	}
	public enum 小説タイプ: String {
		case 短編 = "t"
		case 連載中 = "r"
		case 完結済連載小説 = "er"
		case すべての連載小説（連載中および完結済） = "re"
		case 短編と完結済連載小説 = "ter"
	}
	public enum 文体: Int {
		case 字下げされておらず・連続改行が多い作品 = 1
		case 字下げされていないが・改行数は平均な作品 = 2
		case 字下げが適切だが・連続改行が多い作品 = 4
		case 字下げが適切でかつ改行数も平均な作品 = 6
	}
	public enum 連載停止中区分: Int {
		case 長期連載停止中を除外 = 1 // 長期連載停止中を除きます
		case 長期連載停止中のみ = 2 // 長期連載停止中のみ取得します
	}
	public enum 最終掲載日種別 {
		case 今週 // (日曜日の午前0時はじまり)
		case 先週
		case 過去7日間
		case 今月
		case 先月
		case タイムスタンプ(ClosedRange<Int>)
		var value: String {
			switch self {
			case .今週: return "thisweek"
			case .先週: return "lastweek"
			case .過去7日間: return "sevenday"
			case .今月: return "thismonth"
			case .先月: return "lastmonth"
			case .タイムスタンプ(let range): return "\(String(range.lowerBound))-\(String(range.upperBound))"
			}
		}
	}
	public enum NarouError: Error {
		case unexpectedJsonType
	}
	// mark: -
	fileprivate class 出力形式指定: NarouQueryParameter {
		fileprivate var name: String { return ParameterKey.出力形式.rawValue }
		fileprivate let out: 出力形式
		fileprivate init(out: 出力形式) {
			self.out = out
		}
		fileprivate var value: String { return out.rawValue }
	}
	public class 検索対象範囲指定: NarouQueryParameter {
		public var name: String { self.検索対象範囲.rawValue }
		public let 検索対象範囲: 検索対象範囲
		public init(_ 検索対象範囲: 検索対象範囲) {
			self.検索対象範囲 = 検索対象範囲
		}
		public var value: String { return "1" }
	}
	public class 検索単語指定: NarouQueryParameter {
		public var name: String { ParameterKey.単語指定.rawValue }
		public let keywords: String
		public init(_ keywords: String) {
			self.keywords = keywords
		}
		public var value: String { return keywords }
	}
	public class 検索単語除外指定: NarouQueryParameter {
		public var name: String { ParameterKey.単語除外.rawValue }
		public let keywords: String
		public init(_ keywords: String) {
			self.keywords = keywords
		}
		public var value: String { return keywords }
	}
	public class 出力順序指定: NarouQueryParameter {
		public var name: String { ParameterKey.出力順序.rawValue }
		public let 出力順序: 出力順序
		public init(_ 出力順序: 出力順序) {
			self.出力順序 = 出力順序
		}
		public var value: String { return 出力順序.key } // not rawValue
	}
	public class 大分類指定: NarouQueryParameter {
		public var name: String { ParameterKey.大分類指定.rawValue }
		public let 大分類: 大分類
		public init(_ 大分類: 大分類) {
			self.大分類 = 大分類
		}
		public var value: String { return String(大分類.rawValue) }
	}
	public class 大分類除外: NarouQueryParameter {
		public var name: String { ParameterKey.大分類除外.rawValue }
		public let 大分類: 大分類
		public init(_ 大分類: 大分類) {
			self.大分類 = 大分類
		}
		public var value: String { return String(大分類.rawValue) }
	}
	public class ジャンル指定: NarouQueryParameter {
		public var name: String { ParameterKey.ジャンル指定.rawValue }
		public let ジャンル: [ジャンル]
		public init(_ ジャンル: [ジャンル]) {
			self.ジャンル = ジャンル
		}
		public var value: String { return self.ジャンル.map { String($0.rawValue) }.joined(separator: "-") }
	}
	public class ジャンル除外: NarouQueryParameter {
		public var name: String { ParameterKey.ジャンル除外.rawValue }
		public let ジャンル: [ジャンル]
		public init(_ ジャンル: [ジャンル]) {
			self.ジャンル = ジャンル
		}
		public var value: String { return self.ジャンル.map { String($0.rawValue) }.joined(separator: "-") }
	}
	public class ユーザID指定: NarouQueryParameter {
		public var name: String { ParameterKey.ユーザID指定.rawValue }
		public let ユーザID: [String]
		public init(_ ユーザID: [String]) {
			self.ユーザID = ユーザID
		}
		public var value: String { return self.ユーザID.joined(separator: "-") }
	}
	public class 登録必須キーワード指定: NarouQueryParameter {
		public var name: String { 登録必須キーワード指定.key.rawValue }
		public let 登録必須キーワード指定: 登録必須キーワード指定区分
		public init(_ 登録必須キーワード: 登録必須キーワード指定区分) {
			self.登録必須キーワード指定 = 登録必須キーワード
		}
		public var value: String { return "1" }
	}
	public class 登録必須キーワード除外: NarouQueryParameter {
		public var name: String { 登録必須キーワード除外.key.rawValue }
		public let 登録必須キーワード除外: 登録必須キーワード除外区分
		public init(_ 登録必須キーワード: 登録必須キーワード除外区分) {
			self.登録必須キーワード除外 = 登録必須キーワード
		}
		public var value: String { return "1" }
	}
	public class 連載停止中指定: NarouQueryParameter {
		public var name: String { ParameterKey.連載停止中指定.rawValue }
		public let 連載停止中: 連載停止中区分
		public init(_ 連載停止中: 連載停止中区分) {
			self.連載停止中 = 連載停止中
		}
		public var value: String { return String(連載停止中.rawValue) }
	}
	public class 最終掲載日指定: NarouQueryParameter {
		public var name: String { ParameterKey.最終掲載日指定.rawValue }
		public let 最終掲載日: 最終掲載日種別
		public init(_ 最終掲載日: 最終掲載日種別) {
			self.最終掲載日 = 最終掲載日
		}
		public var value: String { return 最終掲載日.value }
	}
	public class Nコード指定: NarouQueryParameter {
		public var name: String { ParameterKey.Nコード.rawValue }
		public let Nコード: [String]
		public init(_ Nコード: [String]) {
			self.Nコード = Nコード
		}
		public var value: String { return Nコード.joined(separator: "-") }
	}
	public class ピックアップ指定: NarouQueryParameter {
		public var name: String { ParameterKey.ピックアップ指定.rawValue }
		public init() {
		}
		public var value: String { return "1" }
	}
	public class 最大出力数: NarouQueryParameter {
		public var name: String { ParameterKey.最大出力数.rawValue }
		public let count: Int
		public init(_ count: Int) {
			self.count = count
		}
		public var value: String { return String(count) }
	}
	/*
	public func query(parameters: [NarouQueryParameter], completion: ((NarouQueryResponse?, Error?)->())) {
		let 出力形式 = NarouFetcher.出力形式指定(out: .json)
		if let url = self.makeQueryURL(parameters: parameters + [出力形式]) {
			print(url)
			do {
				let data = try Data(contentsOf: url)
				if let json = try JSONSerialization.jsonObject(with: data, options: []) as? NSArray {
					let response = NarouQueryResponse(array: json)
					completion(response, nil)
				}
				else {
					completion(nil, NarouFetcher.NarouError.unexpectedJsonType)
				}
			}
			catch {
				completion(nil, error)
			}
		}
	}
	*/
	public func makeQuery() -> NarouQuery {
		return NarouQuery()
	}
}

public class NarouQuery {
	fileprivate init() {
	}
	var parameters = [NarouQueryParameter]()
	public func 検索対象範囲指定(_ 検索対象範囲: [NarouFetcher.検索対象範囲]) {
		self.parameters += 検索対象範囲.map { NarouFetcher.検索対象範囲指定($0) }
	}
	public func 検索単語指定(_ keyword: String) {
		self.parameters += [NarouFetcher.検索単語指定(keyword)]
	}
	public func 検索単語除外指定(_ keyword: String) {
		self.parameters += [NarouFetcher.検索単語除外指定(keyword)]
	}
	public func 出力順序指定(_ 出力順序: NarouFetcher.出力順序) {
		self.parameters += [NarouFetcher.出力順序指定(出力順序)]
	}
	public func 大分類指定(_ 大分類: NarouFetcher.大分類) {
		self.parameters += [NarouFetcher.大分類指定(大分類)]
	}
	public func 大分類除外(_ 大分類: NarouFetcher.大分類) {
		self.parameters += [NarouFetcher.大分類除外(大分類)]
	}
	public func ジャンル指定(_ ジャンル: [NarouFetcher.ジャンル]) {
		self.parameters += [NarouFetcher.ジャンル指定(ジャンル)]
	}
	public func ジャンル除外(_ ジャンル: [NarouFetcher.ジャンル]) {
		self.parameters += [NarouFetcher.ジャンル除外(ジャンル)]
	}
	public func ユーザID指定(_ ユーザID: [String]) {
		self.parameters += [NarouFetcher.ユーザID指定(ユーザID)]
	}
	public func 登録必須キーワード指定(_ 登録必須キーワード: [NarouFetcher.登録必須キーワード指定区分]) {
		self.parameters += 登録必須キーワード.map { NarouFetcher.登録必須キーワード指定($0)  }
	}
	public func 登録必須キーワード除外(_ 登録必須キーワード: [NarouFetcher.登録必須キーワード除外区分]) {
		self.parameters += 登録必須キーワード.map { NarouFetcher.登録必須キーワード除外($0)  }
	}
	public func 連載停止中指定(_ 連載停止中: NarouFetcher.連載停止中区分) {
		self.parameters += [NarouFetcher.連載停止中指定(連載停止中)]
	}
	public func 最終掲載日指定(_ 最終掲載日: NarouFetcher.最終掲載日種別) {
		self.parameters += [NarouFetcher.最終掲載日指定(最終掲載日)]
	}
	public func Nコード指定(_ ncode: [String]) {
		self.parameters += [NarouFetcher.Nコード指定(ncode)]
	}
	public func ピックアップ指定() {
		self.parameters += [NarouFetcher.ピックアップ指定()]
	}
	public func 最大出力数(_ count: Int) {
		self.parameters += [NarouFetcher.最大出力数(count)]
	}
	public func makeQueryURL(parameters: [NarouQueryParameter]) -> URL? {
		if var components = URLComponents(string: NarouFetcher.api) {
			components.queryItems = parameters.map { URLQueryItem(name: $0.name, value: $0.value) }
			// print(String(describing: components.url))
			return components.url
		}
		return nil
	}
	public func fetch(completion: ((NarouQueryResponse?, Error?)->())) {
		let 出力形式 = NarouFetcher.出力形式指定(out: .json)
		if let url = self.makeQueryURL(parameters: self.parameters + [出力形式]) {
			// print(url)
			do {
				let data = try Data(contentsOf: url)
				if let json = try JSONSerialization.jsonObject(with: data, options: []) as? NSArray {
					let response = NarouQueryResponse(array: json)
					completion(response, nil)
				}
				else {
					completion(nil, NarouFetcher.NarouError.unexpectedJsonType)
				}
			}
			catch {
				completion(nil, error)
			}
		}
	}
}

public class NarouQueryResponse {
	public var entries: [NarouShosetsuEntry]
	fileprivate init(array: NSArray) {
		let entries = array.compactMap { $0 as? NSDictionary }.map { NarouShosetsuEntry(dictionary: $0) }
		self.entries = entries.filter { $0.Nコード != nil }
	}
	var count: Int { return self.entries.count }
}

public class NarouShosetsuEntry: CustomStringConvertible {
	public enum Keys: String {
		case 全小説出力数 = "allcount"
		case タイトル = "title"
		case Nコード = "ncode"
		case 作者のユーザID = "userid"
		case 作者名 = "writer"
		case あらすじ = "story"
		case 大分類 = "biggenre"
		case ジャンル = "genre"
		case キーワード = "keyword"
		case 初回掲載日 = "general_firstup" // 初回掲載日 YYYY-MM-DD HH:MM:SSの形式
		case 最終掲載日 = "general_lastup" // 最終掲載日 YYYY-MM-DD HH:MM:SSの形式
		case 小説タイプ = "novel_type" // 連載の場合は1、短編の場合は2
		case 連載中 = "end" // 短編小説と完結済小説は0となっています。連載中は1です。
		case 全掲載部分数 = "general_all_no" // 全掲載部分数です。短編の場合は1です。
		case 小説文字数 = "length" // 小説文字数です。スペースや改行は文字数としてカウントしません。
		case 読了時間（分） = "time" // 読了時間(分単位)です。読了時間は小説文字数÷500を切り上げした数値です。
		case 長期連載停止中 = "isstop" // 長期連載停止中なら1、それ以外は0です。
		case ボーイズラブ = "isr15" // 登録必須キーワードに「R15」が含まれる場合は1、それ以外は0です。
		case ガールズラブ = "isbl" // 登録必須キーワードに「ボーイズラブ」が含まれる場合は1、それ以外は0です。
		case 残酷な描写あり = "iszankoku" // 登録必須キーワードに「ガールズラブ」が含まれる場合は1、それ以外は0です。
		case 異世界転生 = "istensei" // 登録必須キーワードに「異世界転生」が含まれる場合は1、それ以外は0です。
		case 異世界転移 = "istenni" // 登録必須キーワードに「異世界転移」が含まれる場合は1、それ以外は0です。
		case 携帯ＰＣ区分 = "pc_or_k" // 1はケータイのみ、2はPCのみ、3はPCとケータイで投稿された作品です。対象は投稿と次話投稿時のみで、どの端末で執筆されたかを表すものではありません。
		case 総合評価ポイント = "global_point" // 総合評価ポイント(=(ブックマーク数×2)+評価点)
		case 日間ポイント = "daily_point" // 日間ポイント(ランキング集計時点から過去24時間以内で新たに登録されたブックマークや評価が対象)
		case 週間ポイント = "weekly_point" // (ランキング集計時点から過去7日以内で新たに登録されたブックマークや評価が対象)
		case 月間ポイント = "quarter_point" // 四半期ポイント(ランキング集計時点から過去90日以内で新たに登録されたブックマークや評価が対象)
		case 年間ポイント = "yearly_point" // 年間ポイント(ランキング集計時点から過去365日以内で新たに登録されたブックマークや評価が対象)
		case ブックマーク数 = "fav_novel_cnt" // ブックマーク数
		case 感想数 = "impression_cnt" // 感想数
		case レビュー数 = "review_cnt"
		case 評価点 = "all_point"
		case 評価者数 = "all_hyoka_cnt"
		case 挿絵の数 = "sasie_cnt"
		case 会話率 = "kaiwaritu"
		case 更新日時 = "novelupdated_at" // 小説の更新日時
		case 更新日時（システム用） = "updated_at" // 最終更新日時(注意：システム用で小説更新時とは関係ありません)
	}
	public let dictionary: NSDictionary
	public init(dictionary: NSDictionary) {
		self.dictionary = dictionary
	}
	public var 全小説出力数: Int? { self.dictionary[Keys.全小説出力数.rawValue] as? Int }
	public var タイトル: String? { self.dictionary[Keys.タイトル.rawValue] as? String }
	public var Nコード: String? { self.dictionary[Keys.Nコード.rawValue] as? String }
	public var 作者のユーザID: String? { self.dictionary[Keys.作者のユーザID.rawValue] as? String }
	public var 作者名: String? { self.dictionary[Keys.作者名.rawValue] as? String }
	public var あらすじ: String? { self.dictionary[Keys.あらすじ.rawValue] as? String }
	public var 大分類: NarouFetcher.大分類? { return (self.dictionary[Keys.大分類.rawValue] as? Int).flatMap { NarouFetcher.大分類(rawValue: $0) } }
	public var ジャンル: NarouFetcher.ジャンル? { (self.dictionary[Keys.ジャンル.rawValue] as? Int).flatMap { NarouFetcher.ジャンル(rawValue: $0) } }
	public var キーワード: [String]? { (self.dictionary[Keys.キーワード.rawValue] as? String).flatMap { $0.components(separatedBy: CharacterSet.whitespaces) } }
	public var 初回掲載日: NarouDate? { (self.dictionary[Keys.初回掲載日.rawValue] as? String).flatMap { NarouDate(string: $0) } }
	public var 最終掲載日: NarouDate? { (self.dictionary[Keys.最終掲載日.rawValue] as? String).flatMap { NarouDate(string: $0) } }
	public var 小説タイプ: Int? { self.dictionary[Keys.小説タイプ.rawValue] as? Int }
	public var 連載中: Bool? { (self.dictionary[Keys.連載中.rawValue] as? Bool) }
	public var 全掲載部分数: Int? { self.dictionary[Keys.全掲載部分数.rawValue] as? Int }
	public var 小説文字数: Int? { self.dictionary[Keys.小説文字数.rawValue] as? Int }
	public var 読了時間（分）: Int? { self.dictionary[Keys.読了時間（分）.rawValue] as? Int }
	public var 長期連載停止中: Bool? { self.dictionary[Keys.長期連載停止中.rawValue] as? Bool }
	public var ボーイズラブ: Bool { self.dictionary[Keys.ボーイズラブ.rawValue] as? Bool ?? false }
	public var ガールズラブ: Bool { self.dictionary[Keys.ガールズラブ.rawValue] as? Bool ?? false }
	public var 残酷な描写あり: Bool { self.dictionary[Keys.残酷な描写あり.rawValue] as? Bool ?? false }
	public var 異世界転生: Bool { self.dictionary[Keys.異世界転生.rawValue] as? Bool ?? false }
	public var 異世界転移: Bool { self.dictionary[Keys.異世界転移.rawValue] as? Bool ?? false }
	public var 携帯ＰＣ区分: String? { self.dictionary[Keys.携帯ＰＣ区分.rawValue] as? String }
	public var 総合評価ポイント: Int? { self.dictionary[Keys.総合評価ポイント.rawValue] as? Int }
	public var 日間ポイント: Int? { self.dictionary[Keys.日間ポイント.rawValue] as? Int }
	public var 週間ポイント: Int? { self.dictionary[Keys.週間ポイント.rawValue] as? Int }
	public var 月間ポイント: Int? { self.dictionary[Keys.月間ポイント.rawValue] as? Int }
	public var 年間ポイント: Int? { self.dictionary[Keys.年間ポイント.rawValue] as? Int}
	public var ブックマーク数: Int? { self.dictionary[Keys.ブックマーク数.rawValue] as? Int }
	public var 感想数: Int? { self.dictionary[Keys.感想数.rawValue] as? Int }
	public var レビュー数: Int? { self.dictionary[Keys.レビュー数.rawValue] as? Int }
	public var 評価点: Int? { self.dictionary[Keys.評価点.rawValue] as? Int }
	public var 評価者数: Int? { self.dictionary[Keys.評価者数.rawValue] as? Int }
	public var 挿絵の数: Int? { self.dictionary[Keys.挿絵の数.rawValue] as? Int }
	public var 会話率: Int? { self.dictionary[Keys.会話率.rawValue] as? Int }
	public var 更新日時: NarouDate? { (self.dictionary[Keys.更新日時.rawValue] as? String).flatMap { NarouDate(string: $0) } }
	public var 更新日時（システム用）: NarouDate? { (self.dictionary[Keys.更新日時（システム用）.rawValue] as? String).flatMap { NarouDate(string: $0) } }
	public var description: String { self.dictionary.xdescription }
}

/*
typealias T = NarouManager
let fetcher = NarouManager.shared
let json = T.出力形式指定(out: .json)
let keywords = T.検索単語指定(keywords: "魔王")
let n9219fx = T.Nコード指定(Nコード: ["n9219fx"])
fetcher.query(parameters: [json, keywords]) {
		print("** end **")
}
*/
