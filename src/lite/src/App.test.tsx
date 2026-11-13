import { describe, it, expect, afterEach } from 'vitest'
import { render, screen, cleanup } from '@testing-library/react'
import '@testing-library/jest-dom/vitest'
import App from './App'

// 冒烟：外壳三页签与三页必须渲染，未知路由回报价页
describe('外壳与页签冒烟', () => {
  it('渲染品牌与三页签', () => {
    window.history.pushState({}, '', '/')
    render(<App />)
    expect(screen.getAllByText('量潮商务云').length).toBeGreaterThan(0)
    expect(screen.getByRole('link', { name: /报价/ })).toBeInTheDocument()
    expect(screen.getByRole('link', { name: /合同/ })).toBeInTheDocument()
    expect(screen.getByRole('link', { name: /我的/ })).toBeInTheDocument()
  })

  const tabs = [
    { path: '/', text: '报价' },
    { path: '/contracts', text: '合同' },
    { path: '/mine', text: '我的' },
  ]

  for (const { path, text } of tabs) {
    it(`渲染 ${path}`, () => {
      window.history.pushState({}, '', path)
      render(<App />)
      expect(screen.getAllByText(text).length).toBeGreaterThan(0)
    })
  }

  it('未知路径重定向到报价页', () => {
    window.history.pushState({}, '', '/whatever')
    render(<App />)
    expect(screen.getAllByText('报价').length).toBeGreaterThan(0)
  })
})

afterEach(cleanup)
