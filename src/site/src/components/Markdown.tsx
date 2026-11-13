import ReactMarkdown from 'react-markdown'
import remarkGfm from 'remark-gfm'

// markdown 渲染：GFM（表格、删除线、任务列表、自动链接）
// 默认不解析原始 HTML，内容不经 dangerouslySetInnerHTML
function Markdown({ children }: { children: string }) {
  return <ReactMarkdown remarkPlugins={[remarkGfm]}>{children}</ReactMarkdown>
}

export default Markdown
