//
//	NarouFetcherTests.swift
//	NarouFetcherTests
//
//	Created by Kaz Yoshikawa on 12/26/19.
//

import XCTest
import NarouFetcher

class NarouFetcherTests: XCTestCase {
	
	let fetcher = NarouFetcher.shared

	override func setUp() {
		// Put setup code here. This method is called before the invocation of each test method in the class.
	}
	
	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
	}
	
	func testExample() {
		let keyword = "魔王"

		typealias T = NarouFetcher
		self.fetcher.query(parameters: [
			T.検索単語指定(keyword),
//			T.検索対象範囲指定(.あらすじ),
//			T.検索対象範囲指定(.タイトル),
			T.最終掲載日指定(.先月),
//			T.ピックアップ指定()
		]) { (response, error) in
			if let response = response {
				for entry in response.entries {
					print("~~~~~~~~~~")
					print("ncode:", entry.Nコード ?? "nil")
					print("title:", entry.タイトル ?? "nil")
					if let あらすじ = entry.あらすじ, let range = あらすじ.range(of: keyword) {
						print("あらすじ: ", あらすじ[range])
					}
					if let タイトル = entry.タイトル, let range = タイトル.range(of: keyword) {
						print("タイトル: ", タイトル[range])
					}
					if let キーワード = entry.キーワード, let range = キーワード.joined().range(of: keyword) {
						print("キーワード: ", キーワード.joined()[range])
					}
					if let 作者名 = entry.作者名, let range = 作者名.range(of: keyword) {
						print("作者名: ", 作者名[range])
					}
				}
			}
		}
	}
	
	func testPerformanceExample() {
		// This is an example of a performance test case.
		measure {
			// Put the code you want to measure the time of here.
		}
	}
	
}
