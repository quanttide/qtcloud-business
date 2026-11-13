import type { ReactNode } from 'react'
import { EXTERNAL_LINKS, ROUTE_PATHS } from '../routes'

// 站点外框：导航 + 页头 + 内容区，路由出口由调用方以 children 传入
function Layout({ children }: { children: ReactNode }) {
  return (
    <div className="app">
      <nav className="site-nav">
        <div className="nav-inner">
          <a className="site-brand" href={ROUTE_PATHS.home}>
            量潮商务云
          </a>
          <div className="site-links">
            <a href={EXTERNAL_LINKS.studio} target="_blank" rel="noreferrer">
              Studio
            </a>
            <a href={EXTERNAL_LINKS.lite} target="_blank" rel="noreferrer">
              Lite
            </a>
          </div>
        </div>
      </nav>

      <header className="hero">
        <h1>量潮商务云</h1>
        <p>B2B 销售的报价制定与合同管理</p>
      </header>

      <div className="content">{children}</div>
    </div>
  )
}

export default Layout
