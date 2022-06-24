/*****************************************************************************
 * Copyright (C) 2019 VLC authors and VideoLAN
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston MA 02110-1301, USA.
 *****************************************************************************/
#include "videosurface.hpp"
#include "maininterface/mainctx.hpp"
#include "widgets/native/customwidgets.hpp" //for qtEventToVLCKey
#include <QSGRectangleNode>

VideoSurfaceProvider::VideoSurfaceProvider(QObject* parent)
    : QObject(parent)
{
}

bool VideoSurfaceProvider::isEnabled()
{
    QMutexLocker lock(&m_voutlock);
    return m_voutWindow != nullptr;
}

bool VideoSurfaceProvider::hasVideoEmbed() const
{
    return m_videoEmbed;
}

void VideoSurfaceProvider::enable(vlc_window_t* voutWindow)
{
    assert(voutWindow);
    {
        QMutexLocker lock(&m_voutlock);
        m_voutWindow = voutWindow;
    }
    emit videoEnabledChanged(true);
}

void VideoSurfaceProvider::disable()
{
    setVideoEmbed(false);
    {
        QMutexLocker lock(&m_voutlock);
        m_voutWindow = nullptr;
    }
    emit videoEnabledChanged(false);
}

void VideoSurfaceProvider::setVideoEmbed(bool embed)
{
    m_videoEmbed = embed;
    emit hasVideoEmbedChanged(embed);
}

void VideoSurfaceProvider::onWindowClosed()
{
    QMutexLocker lock(&m_voutlock);
    if (m_voutWindow)
        vlc_window_ReportClose(m_voutWindow);
}

void VideoSurfaceProvider::onMousePressed(int vlcButton)
{
    QMutexLocker lock(&m_voutlock);
    if (m_voutWindow)
        vlc_window_ReportMousePressed(m_voutWindow, vlcButton);
}

void VideoSurfaceProvider::onMouseReleased(int vlcButton)
{
    QMutexLocker lock(&m_voutlock);
    if (m_voutWindow)
        vlc_window_ReportMouseReleased(m_voutWindow, vlcButton);
}

void VideoSurfaceProvider::onMouseDoubleClick(int vlcButton)
{
    QMutexLocker lock(&m_voutlock);
    if (m_voutWindow)
        vlc_window_ReportMouseDoubleClick(m_voutWindow, vlcButton);
}

void VideoSurfaceProvider::onMouseMoved(float x, float y)
{
    QMutexLocker lock(&m_voutlock);
    if (m_voutWindow)
        vlc_window_ReportMouseMoved(m_voutWindow, x, y);
}

void VideoSurfaceProvider::onMouseWheeled(const QWheelEvent& event)
{
    int vlckey = qtWheelEventToVLCKey(event);
    QMutexLocker lock(&m_voutlock);
    if (m_voutWindow)
        vlc_window_ReportKeyPress(m_voutWindow, vlckey);
}

void VideoSurfaceProvider::onKeyPressed(int key, Qt::KeyboardModifiers modifiers)
{
    QKeyEvent event(QEvent::KeyPress, key, modifiers);
    int vlckey = qtEventToVLCKey(&event);
    QMutexLocker lock(&m_voutlock);
    if (m_voutWindow)
        vlc_window_ReportKeyPress(m_voutWindow, vlckey);

}

void VideoSurfaceProvider::onSurfaceSizeChanged(QSizeF size)
{
    emit surfaceSizeChanged(size);
    QMutexLocker lock(&m_voutlock);
    if (m_voutWindow)
        vlc_window_ReportSize(m_voutWindow, size.width(), size.height());
}


VideoSurface::VideoSurface(QQuickItem* parent)
    : QQuickItem(parent)
{
    setAcceptHoverEvents(true);
    setAcceptedMouseButtons(Qt::AllButtons);
    setFlag(ItemAcceptsInputMethod, true);
    setFlag(ItemHasContents, true);

    connect(this, &QQuickItem::xChanged, this, &VideoSurface::onSurfacePositionChanged);
    connect(this, &QQuickItem::yChanged, this, &VideoSurface::onSurfacePositionChanged);
    connect(this, &QQuickItem::widthChanged, this, &VideoSurface::onSurfaceSizeChanged);
    connect(this, &QQuickItem::heightChanged, this, &VideoSurface::onSurfaceSizeChanged);
    connect(this, &VideoSurface::enabledChanged, this, &VideoSurface::updatePositionAndSize);
}

MainCtx* VideoSurface::getCtx()
{
    return m_ctx;
}

void VideoSurface::setCtx(MainCtx* ctx)
{
    m_ctx = ctx;
    emit ctxChanged(ctx);
}

int VideoSurface::qtMouseButton2VLC( Qt::MouseButton qtButton )
{
    switch( qtButton )
    {
        case Qt::LeftButton:
            return 0;
        case Qt::RightButton:
            return 2;
        case Qt::MiddleButton:
            return 1;
        default:
            return -1;
    }
}

void VideoSurface::mousePressEvent(QMouseEvent* event)
{
    int vlc_button = qtMouseButton2VLC( event->button() );
    if( vlc_button >= 0 )
    {
        emit mousePressed(vlc_button);
        event->accept();
    }
    else
        event->ignore();
}

void VideoSurface::mouseReleaseEvent(QMouseEvent* event)
{
    int vlc_button = qtMouseButton2VLC( event->button() );
    if( vlc_button >= 0 )
    {
        emit mouseReleased(vlc_button);
        event->accept();
    }
    else
        event->ignore();
}

void VideoSurface::mouseMoveEvent(QMouseEvent* event)
{
    QPointF current_pos = event->localPos();
    emit mouseMoved(current_pos.x() , current_pos.y());
    event->accept();
}

void VideoSurface::hoverMoveEvent(QHoverEvent* event)
{
    QPointF current_pos = event->posF();
    if (current_pos != m_oldHoverPos)
    {
        emit mouseMoved(current_pos.x(), current_pos.y());
        m_oldHoverPos = current_pos;
    }
    event->accept();
}

void VideoSurface::mouseDoubleClickEvent(QMouseEvent* event)
{
    int vlc_button = qtMouseButton2VLC( event->button() );
    if( vlc_button >= 0 )
    {
        emit mouseDblClicked(vlc_button);
        event->accept();
    }
    else
        event->ignore();
}

void VideoSurface::keyPressEvent(QKeyEvent* event)
{
    emit keyPressed(event->key(), event->modifiers());
    event->ignore();
}

void VideoSurface::geometryChanged(const QRectF& newGeometry, const QRectF& oldGeometry)
{
    QQuickItem::geometryChanged(newGeometry, oldGeometry);
    onSurfaceSizeChanged();
}

#if QT_CONFIG(wheelevent)
void VideoSurface::wheelEvent(QWheelEvent *event)
{
    emit mouseWheeled(*event);
    event->ignore();
}
#endif

Qt::CursorShape VideoSurface::getCursorShape() const
{
    return cursor().shape();
}

void VideoSurface::setCursorShape(Qt::CursorShape shape)
{
    setCursor(shape);
}

QSGNode*VideoSurface::updatePaintNode(QSGNode* oldNode, QQuickItem::UpdatePaintNodeData*)
{
    QSGRectangleNode* node = static_cast<QSGRectangleNode*>(oldNode);

    if (!node)
    {
        node = this->window()->createRectangleNode();
        node->setColor(Qt::transparent);
    }
    node->setRect(this->boundingRect());

    if (m_provider == nullptr)
    {
        if (m_ctx == nullptr)
            return node;
        m_provider =  m_ctx->getVideoSurfaceProvider();
        if (!m_provider)
            return node;

        //forward signal to the provider
        connect(this, &VideoSurface::mouseMoved, m_provider, &VideoSurfaceProvider::onMouseMoved);
        connect(this, &VideoSurface::mousePressed, m_provider, &VideoSurfaceProvider::onMousePressed);
        connect(this, &VideoSurface::mouseDblClicked, m_provider, &VideoSurfaceProvider::onMouseDoubleClick);
        connect(this, &VideoSurface::mouseReleased, m_provider, &VideoSurfaceProvider::onMouseReleased);
        connect(this, &VideoSurface::mouseWheeled, m_provider, &VideoSurfaceProvider::onMouseWheeled);
        connect(this, &VideoSurface::keyPressed, m_provider, &VideoSurfaceProvider::onKeyPressed);
        connect(this, &VideoSurface::surfaceSizeChanged, m_provider, &VideoSurfaceProvider::onSurfaceSizeChanged, Qt::QueuedConnection);
        connect(this, &VideoSurface::surfacePositionChanged, m_provider, &VideoSurfaceProvider::surfacePositionChanged);

        connect(m_provider, &VideoSurfaceProvider::hasVideoEmbedChanged, this, &VideoSurface::onProviderVideoChanged);

        updatePositionAndSize();
    }
    return node;
}

void VideoSurface::onProviderVideoChanged(bool hasVideo)
{
    if (!hasVideo)
        return;
    updatePositionAndSize();
}

void VideoSurface::onSurfaceSizeChanged()
{
    if (!isEnabled())
        return;
    QQuickWindow* window = this->window();
    if (!window)
        return;
    emit surfaceSizeChanged(size() * window->effectiveDevicePixelRatio());
}

void VideoSurface::onSurfacePositionChanged()
{
    if (!isEnabled())
        return;

    QPointF scenePosition = this->mapToScene(QPointF(0,0));
    QQuickWindow* window = this->window();
    if (!window)
        return;
    qreal dpr = this->window()->effectiveDevicePixelRatio();
    emit surfacePositionChanged(scenePosition * dpr);
}

void VideoSurface::updatePositionAndSize()
{
    if (!isEnabled())
        return;

    QQuickWindow* window = this->window();
    if (!window)
        return;
    qreal dpr = this->window()->effectiveDevicePixelRatio();
    emit surfaceSizeChanged(size() * dpr);
    QPointF scenePosition = this->mapToScene(QPointF(0, 0));
    emit surfacePositionChanged(scenePosition * dpr);
}
