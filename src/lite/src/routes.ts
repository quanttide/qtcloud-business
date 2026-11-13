// 路由路径与链接地址的唯一来源
export const ROUTE_PATHS = {
  quotations: '/',
  contracts: '/contracts',
  mine: '/mine',
} as const

// 底部导航三个页签（顺序即导航顺序：报价、合同、我的）
export const TABS = [
  { path: ROUTE_PATHS.quotations, label: '报价', icon: 'quotation' },
  { path: ROUTE_PATHS.contracts, label: '合同', icon: 'contract' },
  { path: ROUTE_PATHS.mine, label: '我的', icon: 'mine' },
] as const

export type TabIcon = (typeof TABS)[number]['icon']
