import type { ReactNode } from 'react'
import { NavLink } from 'react-router-dom'
import { TABS, type TabIcon } from '../routes'

// 线性图标：报价=单据、合同=签署、我的=人形；当前页着色
const ICONS: Record<TabIcon, ReactNode> = {
  quotation: (
    <svg viewBox="0 0 24 24" width="24" height="24" aria-hidden="true">
      <rect
        x="5"
        y="4.5"
        width="14"
        height="16"
        rx="2"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.7"
      />
      <path
        d="M8.5 9.5h7M8.5 13.5h7M8.5 17h4"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.7"
        strokeLinecap="round"
      />
    </svg>
  ),
  contract: (
    <svg viewBox="0 0 24 24" width="24" height="24" aria-hidden="true">
      <path
        d="M6 3.5h9l3 3v14H6z"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.7"
        strokeLinejoin="round"
      />
      <path
        d="M9 14.5c1.2-2 2.4-2.5 3.4-1.4.8.9 1.6.6 2.6-1.1M9 17.5h6"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.7"
        strokeLinecap="round"
      />
    </svg>
  ),
  mine: (
    <svg viewBox="0 0 24 24" width="24" height="24" aria-hidden="true">
      <circle cx="12" cy="8" r="3.5" fill="none" stroke="currentColor" strokeWidth="1.7" />
      <path
        d="M5 20c.8-3.6 3.6-5.5 7-5.5s6.2 1.9 7 5.5"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.7"
        strokeLinecap="round"
      />
    </svg>
  ),
}

// 底部导航（微信式）：图标在上、文字在下，当前页高亮
function TabBar() {
  return (
    <nav className="tabBar" aria-label="主导航">
      {TABS.map((tab) => (
        <NavLink
          key={tab.path}
          to={tab.path}
          end={tab.path === '/'}
          className={({ isActive }) => `tabItem${isActive ? ' active' : ''}`}
        >
          <span className="tabIcon">{ICONS[tab.icon]}</span>
          <span className="tabLabel">{tab.label}</span>
        </NavLink>
      ))}
    </nav>
  )
}

export default TabBar
