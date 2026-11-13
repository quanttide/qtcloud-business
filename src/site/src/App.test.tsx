import { describe, it, expect, afterEach } from 'vitest'
import { render, screen, cleanup } from '@testing-library/react'
import '@testing-library/jest-dom/vitest'
import App from './App'

// 冒烟：首页必须渲染出内容，未知路由回首页。白屏会在这里失败
describe('页面渲染冒烟', () => {
  it('渲染首页', () => {
    window.history.pushState({}, '', '/')
    render(<App />)
    expect(screen.getAllByText(/量潮商务云/).length).toBeGreaterThan(0)
  })

  it('未知路径重定向到首页', () => {
    window.history.pushState({}, '', '/whatever')
    render(<App />)
    expect(screen.getAllByText(/量潮商务云/).length).toBeGreaterThan(0)
  })

  it('首页不渲染元数据', () => {
    window.history.pushState({}, '', '/')
    render(<App />)
    expect(screen.queryByText(/^title:/)).toBeNull()
    expect(screen.queryByText(/^description:/)).toBeNull()
  })

  it('导航含 studio 与 lite 连接引用', () => {
    window.history.pushState({}, '', '/')
    render(<App />)
    const studio = screen.getByRole('link', { name: 'Studio' })
    expect(studio).toHaveAttribute('href', 'https://business.cloud.quanttide.com')
    expect(studio).toHaveAttribute('target', '_blank')
    const lite = screen.getByRole('link', { name: 'Lite' })
    expect(lite).toHaveAttribute('href', 'https://lite.business.cloud.quanttide.com')
    expect(lite).toHaveAttribute('target', '_blank')
  })

  it('首页渲染产品定位正文', () => {
    window.history.pushState({}, '', '/')
    render(<App />)
    expect(screen.getAllByText(/报价制定/).length).toBeGreaterThan(0)
    expect(screen.getAllByText(/合同管理/).length).toBeGreaterThan(0)
  })
})

afterEach(cleanup)
