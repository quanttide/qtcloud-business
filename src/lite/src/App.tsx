import { BrowserRouter, Navigate, Routes, Route } from 'react-router-dom'
import AppBar from './components/AppBar'
import TabBar from './components/TabBar'
import Quotations from './pages/Quotations'
import Contracts from './pages/Contracts'
import Mine from './pages/Mine'
import { ROUTE_PATHS } from './routes'
import './App.css'

// 路由表单独导出，便于测试
export function AppRoutes() {
  return (
    <Routes>
      <Route path={ROUTE_PATHS.quotations} element={<Quotations />} />
      <Route path={ROUTE_PATHS.contracts} element={<Contracts />} />
      <Route path={ROUTE_PATHS.mine} element={<Mine />} />
      <Route path="*" element={<Navigate to={ROUTE_PATHS.quotations} replace />} />
    </Routes>
  )
}

// 外壳：微信式顶栏 + 底部三页签（报价 / 合同 / 我的）
function App() {
  return (
    <BrowserRouter>
      <div className="liteApp">
        <AppBar />
        <main className="liteMain">
          <AppRoutes />
        </main>
        <TabBar />
      </div>
    </BrowserRouter>
  )
}

export default App
