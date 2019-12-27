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
		
		let query = NarouFetcher.shared.makeQuery()
		query.検索単語指定(keyword)
		query.検索対象範囲指定([.あらすじ, .タイトル])
		query.最終掲載日指定(.先月)
		query.fetch { (response, error) in
			if let error = error {
				print("\(error)")
			}
			if let response = response {
				for entry in response.entries {
					print("~~~~~~~~~~")
					print("ncode:", entry.Nコード ?? "nil")
					print("title:", entry.タイトル ?? "nil")
					print("あらすじ:", entry.あらすじ ?? "nil")
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
