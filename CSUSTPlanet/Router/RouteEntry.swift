//
//  RouteEntry.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2026/11/19.
//

struct RouteEntry: Hashable {
    let path: String
    private let payload: AnyHashable

    init<Params: RouteParams>(path: String, params: Params) {
        self.path = path
        payload = AnyHashable(params)
    }

    func params<Params: RouteParams>(as _: Params.Type) -> Params? {
        payload.base as? Params
    }
}
