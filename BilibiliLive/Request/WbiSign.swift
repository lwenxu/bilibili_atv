//
//  WbiSign.swift
//  BilibiliLive
//
//  Created by 徐鹏飞 on 2023/6/4.
//

import CryptoKit
import Foundation

let mixinKeyEncTab: [Int] = [
    46, 47, 18, 2, 53, 8, 23, 32, 15, 50, 10, 31, 58, 3, 45, 35, 27, 43, 5, 49,
    33, 9, 42, 19, 29, 28, 14, 39, 12, 38, 41, 13, 37, 48, 7, 16, 24, 55, 40,
    61, 26, 17, 0, 1, 60, 51, 30, 4, 22, 25, 54, 21, 56, 59, 6, 63, 57, 62, 11,
    36, 20, 34, 44, 52,
]
//
//// 对 imgKey 和 subKey 进行字符顺序打乱编码
func getMixinKey(orig: String) -> String {
    var temp = ""
    for key in mixinKeyEncTab {
        temp.append(orig[orig.index(orig.startIndex, offsetBy: key)])
    }
    return String(temp[temp.startIndex...temp.index(temp.startIndex, offsetBy: 31)])
}

// 为请求参数进行 wbi 签名
func encWbi(params: [String: String], img_key: String, sub_key: String) -> [String: String] {
    let mixin_key = getMixinKey(orig: img_key + sub_key),
        curr_time = Int(Date().timeIntervalSince1970)

    var params1: [String: String] = [:]
    params1.merge(params) { x, y in
        return y
    }
    params1["wts"] = String(curr_time)

    var query_list: [String] = []
    let sorted_params = params1.sorted(by: { $0.key < $1.key })
    for (k, v) in sorted_params {
        query_list.append(k.addingPercentEncoding(withAllowedCharacters: .alphanumerics)! + "=" + v.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!)
    }

    let query_str = query_list.joined(separator: "&")
    let digest = Insecure.MD5.hash(data: (query_str + mixin_key).data(using: .utf8) ?? Data())
    let wbi_sign = digest.map {
        String(format: "%02hhx", $0)
    }.joined()

    params1["w_rid"] = wbi_sign
    return params1
//    return query_str + "&w_rid=" + wbi_sign
}

// 获取最新的 img_key 和 sub_key
func getWbiKeys() async throws -> [String: String] {
    let res: WbiImg = try await WebRequest.request(url: "https://api.bilibili.com/x/web-interface/nav", parameters: [:])
    let imgUrl = res.wbi_img.img_url
    let subKey = res.wbi_img.sub_url

    let startIdx0 = imgUrl.index(after: imgUrl.lastIndex(of: "/")!)
    let endIdx0 = imgUrl.index(before: imgUrl.lastIndex(of: ".")!)

    let startIdx1 = subKey.index(after: subKey.lastIndex(of: "/")!)
    let endIdx1 = subKey.index(before: subKey.lastIndex(of: ".")!)

    return ["img_key": String(imgUrl[startIdx0...endIdx0]), "sub_key": String(subKey[startIdx1...endIdx1])]
}

func doQuery(params: [String: String]) async -> [String: String] {
    let wbi_keys = try! await getWbiKeys()
    return encWbi(
        params: params, img_key: wbi_keys["img_key"]!, sub_key: wbi_keys["sub_key"]!
    )
}

// @MainActor
// func test() {
//      let wbi_keys = await getWbiKeys()
//     //
//      const query = encWbi(
//         {
//             foo: '114',
//             bar: '514',
//             baz: 1919810
//         },
//         wbi_keys.img_key,
//         wbi_keys.sub_key
//      )
// }
